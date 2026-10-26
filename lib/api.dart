import 'dart:convert';
import 'package:http/http.dart' as http;

class TransferenciaResponse {
  const TransferenciaResponse(this.exitosa, this.mensaje, [this.comprobante, this.saldoActual]);
  final bool exitosa;
  final String mensaje;
  final String? comprobante;
  final double? saldoActual;
}

abstract class TransferenciaApi {
  Future<bool> login(String email, String password);
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto);
  Future<double?> saldo(String cuenta);
}

/// Cliente real: autentica contra el backend y usa JWT para las transferencias.
class HttpTransferenciaApi implements TransferenciaApi {
  HttpTransferenciaApi(this.baseUrl, {http.Client? client}) : client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;
  String? _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode != 200) return false;

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final token = payload['token'] as String?;
      if (token == null || token.isEmpty) return false;

      _token = token;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<double?> saldo(String cuenta) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/accounts/$cuenta/saldo'),
        headers: _headers,
      );

      if (response.statusCode != 200) return null;

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final value = payload['saldo'];
      if (value == null) return null;
      return (value as num).toDouble();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TransferenciaResponse> transferir(String origen, String destino, double monto) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/transferencias'),
        headers: _headers,
        body: jsonEncode({
          'cuentaOrigen': origen,
          'cuentaDestino': destino,
          'monto': monto,
        }),
      );

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return const TransferenciaResponse(false, 'Respuesta inválida del servidor');
      }

      final ok = response.statusCode >= 200 && response.statusCode < 300 && payload['estado'] == 'EXITOSA';
      final mensaje = (payload['mensaje'] ?? 'Error desconocido').toString();
      final comprobante = payload['comprobante'] as String?;
      final saldoActual = payload['saldoActual'] as num?;

      return TransferenciaResponse(
        ok,
        mensaje,
        comprobante,
        saldoActual?.toDouble(),
      );
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
  Future<bool> login(String email, String password) async =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;

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
    return TransferenciaResponse(
      true,
      'Transferencia realizada correctamente',
      'NEX-TRX-${(++_n).toString().padLeft(6, '0')}',
      saldos[origen],
    );
  }
}
