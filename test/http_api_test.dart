import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora_app/api.dart';

http.Response _json(int code, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), code, headers: {'content-type': 'application/json; charset=utf-8'});

HttpTransferenciaApi _api(Future<http.Response> Function(http.Request) f) =>
    HttpTransferenciaApi('http://x', client: MockClient(f));

void main() {
  test('200: exitosa con comprobante y request con el contrato esperado', () async {
    late http.Request visto;
    final api = _api((r) async {
      visto = r;
      return _json(200, {'mensaje': 'Transferencia exitosa', 'comprobante': 'NEX-TRX-000001'});
    });
    final res = await api.transferir('100001', '200001', 150000);
    expect(res.exitosa, isTrue);
    expect(res.comprobante, 'NEX-TRX-000001');
    expect(visto.method, 'POST');
    expect(visto.url.path, '/api/transferencias');
    expect(jsonDecode(visto.body)['cuentaDestino'], '200001');
  });

  for (final c in <(int, Map<String, dynamic>, String)>[
    (400, {'mensaje': 'Saldo insuficiente'}, 'Saldo insuficiente'),
    (403, {'mensaje': 'Operación rechazada por NEXORA Shield', 'reglas': ['NS-04']}, 'NS-04'),
    (404, <String, dynamic>{}, 'no encontrada'),
    (409, <String, dynamic>{}, 'ya fue procesada'),
    (503, <String, dynamic>{}, 'no disponible'),
    (500, <String, dynamic>{}, 'Error del servidor'),
  ]) {
    test('HTTP ${c.$1} se traduce a un mensaje claro', () async {
      final res = await _api((_) async => _json(c.$1, c.$2)).transferir('100001', '200001', 1000);
      expect(res.exitosa, isFalse);
      expect(res.statusCode, c.$1);
      expect(res.mensaje, contains(c.$3));
    });
  }

  test('401 marca la sesión como expirada', () async {
    final res = await _api((_) async => _json(401, {})).transferir('100001', '200001', 1000);
    expect(res.sesionExpirada, isTrue);
  });

  test('cuerpo no JSON no rompe la app', () async {
    final res = await _api((_) async => http.Response('<html>boom</html>', 500)).transferir('100001', '200001', 1000);
    expect(res.exitosa, isFalse);
    expect(res.mensaje, contains('Error del servidor'));
  });

  test('sin conexión informa el problema', () async {
    final res = await _api((_) async => throw Exception('net')).transferir('100001', '200001', 1000);
    expect(res.exitosa, isFalse);
    expect(res.mensaje, contains('No se pudo conectar'));
  });
}
