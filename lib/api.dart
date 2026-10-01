import 'dart:convert';
import 'package:http/http.dart' as http;

class TransferenciaResponse {
  const TransferenciaResponse(this.exitosa, this.mensaje, [this.comprobante]);
  final bool exitosa;
  final String mensaje;
  final String? comprobante;
}

abstract class TransferenciaApi {
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto);
  Future<double?> saldo(String cuenta);
}

/// Cliente real: POST /api/transferencias (contrato del taller).
class HttpTransferenciaApi implements TransferenciaApi {
  HttpTransferenciaApi(this.baseUrl, {http.Client? client}) : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;

  @override
  Future<double?> saldo(String cuenta) async => null; // el contrato no define consulta de saldo

  @override
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto) async {
    try {
      final r = await client.post(
        Uri.parse('$baseUrl/api/transferencias'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cuentaOrigen': origen, 'cuentaDestino': destino, 'monto': monto}),
      );
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final ok = r.statusCode >= 200 && r.statusCode < 300 && j['estado'] == 'EXITOSA';
      return TransferenciaResponse(ok, (j['mensaje'] ?? 'Error desconocido').toString(), j['comprobante'] as String?);
    } catch (_) {
      return const TransferenciaResponse(false, 'No se pudo conectar con el servidor');
    }
  }
}

/// Backend simulado en memoria con las reglas NEXORA Shield (NS-01..NS-03).
class MockTransferenciaApi implements TransferenciaApi {
  final Map<String, double> saldos = {'100001': 500000, '100002': 120000};
  final Set<String> destinosValidos = {'100002', '200001', '200002'};
  int _n = 0;

  @override
  Future<double?> saldo(String cuenta) async => saldos[cuenta];

  @override
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (monto <= 0) return const TransferenciaResponse(false, 'El monto debe ser mayor que cero');
    if (destino == origen || !destinosValidos.contains(destino)) {
      return const TransferenciaResponse(false, 'Cuenta destino inválida');
    }
    if ((saldos[origen] ?? 0) < monto) return const TransferenciaResponse(false, 'Saldo insuficiente');
    saldos[origen] = saldos[origen]! - monto;
    if (saldos.containsKey(destino)) saldos[destino] = saldos[destino]! + monto;
    return TransferenciaResponse(true, 'Transferencia realizada correctamente',
        'NEX-TRX-${(++_n).toString().padLeft(6, '0')}');
  }
}
