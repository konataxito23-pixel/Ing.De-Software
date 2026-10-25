import 'dart:convert';
import 'package:http/http.dart' as http;

class TransferenciaResponse {
  const TransferenciaResponse(this.exitosa, this.mensaje,
      {this.comprobante, this.statusCode, this.sesionExpirada = false});
  final bool exitosa;
  final String mensaje;
  final String? comprobante;
  final int? statusCode;
  final bool sesionExpirada;
}

/// Códigos de error del backend → mensaje claro para el usuario (NEXO-78).
String mensajeParaEstado(int status, [String? detalle]) {
  final base = switch (status) {
    400 => 'Revisa los datos de la transferencia',
    401 => 'Tu sesión expiró. Inicia sesión de nuevo',
    403 => 'Operación rechazada por NEXORA Shield',
    404 => 'Cuenta origen no encontrada',
    409 => 'Esta operación ya fue procesada',
    503 => 'Servicio de seguridad no disponible. Intenta más tarde',
    >= 500 => 'Error del servidor. Intenta más tarde',
    _ => 'No se pudo completar la transferencia',
  };
  if (detalle == null || detalle.isEmpty) return base;
  if (status == 400) return detalle;
  return detalle.contains(base) ? detalle : '$base: $detalle';
}

enum TipoMov { recibida, enviada, pago, tarjeta }

class Movimiento {
  const Movimiento(this.tipo, this.titulo, this.detalle, this.monto, this.fecha);
  final TipoMov tipo;
  final String titulo, detalle, fecha;
  final double monto; // positivo = ingreso, negativo = egreso
}

abstract class TransferenciaApi {
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto);
  Future<double?> saldo(String cuenta);
  Future<List<Movimiento>> movimientos(String cuenta);
}

/// Cliente real. Éxito = HTTP 2xx; cualquier otro código se traduce con [mensajeParaEstado].
class HttpTransferenciaApi implements TransferenciaApi {
  HttpTransferenciaApi(this.baseUrl, {http.Client? client}) : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;

  @override
  Future<double?> saldo(String cuenta) async => null; // el contrato no define consulta de saldo

  @override
  Future<List<Movimiento>> movimientos(String cuenta) async => const []; // sin endpoint en el contrato

  @override
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto) async {
    try {
      final r = await client
          .post(
            Uri.parse('$baseUrl/api/transferencias'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cuentaOrigen': origen, 'cuentaDestino': destino, 'monto': monto}),
          )
          .timeout(const Duration(seconds: 10));
      var j = <String, dynamic>{};
      try {
        final d = jsonDecode(utf8.decode(r.bodyBytes));
        if (d is Map<String, dynamic>) j = d;
      } catch (_) {}
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return TransferenciaResponse(true, (j['mensaje'] ?? 'Transferencia exitosa').toString(),
            comprobante: j['comprobante']?.toString(), statusCode: r.statusCode);
      }
      return TransferenciaResponse(false, mensajeParaEstado(r.statusCode, _detalle(j)),
          statusCode: r.statusCode, sesionExpirada: r.statusCode == 401);
    } catch (_) {
      return const TransferenciaResponse(false, 'No se pudo conectar con el servidor (sin red o tiempo agotado)');
    }
  }

  String? _detalle(Map<String, dynamic> j) {
    final m = j['mensaje'] ?? j['error'] ?? j['motivo'];
    final reglas = j['reglas'];
    final extra = reglas is List && reglas.isNotEmpty ? ' (${reglas.join(', ')})' : '';
    if (m == null && extra.isEmpty) return null;
    return '${m ?? ''}$extra'.trim();
  }
}

/// Backend simulado en memoria con las reglas NEXORA Shield (NS-01..NS-03).
/// Cuentas de prueba para simular errores: 300001 → 403 (Shield), 300002 → 503 (Shield caído).
class MockTransferenciaApi implements TransferenciaApi {
  final Map<String, double> saldos = {'100001': 500000, '100002': 120000};
  final Set<String> destinosValidos = {'100002', '200001', '200002'};
  int _n = 0;
  final List<Movimiento> _movs = [
    const Movimiento(TipoMov.recibida, 'Transferencia recibida', 'Karla Restrepo', 250000, 'Hoy, 08:42'),
    const Movimiento(TipoMov.pago, 'Pago de servicios', 'EPM', -125800, 'Ayer, 16:20'),
    const Movimiento(TipoMov.tarjeta, 'Compra con tarjeta', 'Éxito Laureles', -89900, 'Ayer, 12:15'),
  ];

  @override
  Future<List<Movimiento>> movimientos(String cuenta) async => List.of(_movs);

  @override
  Future<double?> saldo(String cuenta) async => saldos[cuenta];

  @override
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (monto <= 0) {
      return const TransferenciaResponse(false, 'El monto debe ser mayor que cero', statusCode: 400);
    }
    if (destino == '300001') {
      return TransferenciaResponse(false, mensajeParaEstado(403, 'regla NS-04'), statusCode: 403);
    }
    if (destino == '300002') return TransferenciaResponse(false, mensajeParaEstado(503), statusCode: 503);
    if (destino == origen || !destinosValidos.contains(destino)) {
      return const TransferenciaResponse(false, 'Cuenta destino inválida', statusCode: 400);
    }
    if ((saldos[origen] ?? 0) < monto) {
      return const TransferenciaResponse(false, 'Saldo insuficiente', statusCode: 400);
    }
    saldos[origen] = saldos[origen]! - monto;
    if (saldos.containsKey(destino)) saldos[destino] = saldos[destino]! + monto;
    _movs.insert(0, Movimiento(TipoMov.enviada, 'Transferencia enviada', 'Cuenta $destino', -monto, 'Ahora'));
    return TransferenciaResponse(true, 'Transferencia realizada correctamente',
        comprobante: 'NEX-TRX-${(++_n).toString().padLeft(6, '0')}', statusCode: 200);
  }
}
