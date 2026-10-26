import 'dart:convert';
import 'package:http/http.dart' as http;

class TransferenciaResponse {
  const TransferenciaResponse({
    required this.exitosa,
    required this.mensaje,
    this.comprobante,
    this.advertencias = const [],
  });

  final bool exitosa;
  final String mensaje;
  final String? comprobante;
  final List<String> advertencias;

  factory TransferenciaResponse.fromJson(Map<String, dynamic> json) {
    final estado = (json['estado'] ?? '').toString();
    final ok = estado == 'EXITOSA';
    return TransferenciaResponse(
      exitosa: ok,
      mensaje: (json['mensaje'] ?? 'Error desconocido').toString(),
      comprobante: json['comprobante'] as String?,
      advertencias: (json['reglas'] is List)
          ? List<String>.from(json['reglas'].map((e) => e.toString()))
          : (json['advertencias'] is List)
              ? List<String>.from(json['advertencias'].map((e) => e.toString()))
              : const [],
    );
  }
}

abstract class TransferenciaApi {
  Future<void> login(String usuario, String password);
  Future<void> logout();
  Future<List<Map<String, dynamic>>> cuentas();
  Future<TransferenciaResponse> transferir({
    required String origen,
    required String destino,
    required double monto,
    bool confirmar = false,
  });
}

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
  Future<void> login(String usuario, String password) async {
    final r = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario': usuario, 'password': password}),
    );

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      throw Exception(j['mensaje'] ?? 'Credenciales inválidas');
    }

    _token = j['token'] as String?;
  }

  @override
  Future<void> logout() async {
    if (_token == null) return;

    await client.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: _headers,
    );
    _token = null;
  }

  @override
  Future<List<Map<String, dynamic>>> cuentas() async {
    final r = await client.get(
      Uri.parse('$baseUrl/api/cuentas'),
      headers: _headers,
    );
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      throw Exception(j['mensaje'] ?? 'No se pudo cargar las cuentas');
    }
    return List<Map<String, dynamic>>.from((j['cuentas'] ?? []) as List);
  }

  @override
  Future<TransferenciaResponse> transferir({
    required String origen,
    required String destino,
    required double monto,
    bool confirmar = false,
  }) async {
    final body = {
      'cuentaOrigen': origen,
      'cuentaDestino': destino,
      'monto': monto,
      'confirmar': confirmar,
    };

    final r = await client.post(
      Uri.parse('$baseUrl/api/transferencias'),
      headers: _headers,
      body: jsonEncode(body),
    );

    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return TransferenciaResponse.fromJson(j);
  }
}
