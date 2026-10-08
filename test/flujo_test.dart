import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/api.dart';
import 'package:nexora_app/main.dart';

class _ApiSesionVencida implements TransferenciaApi {
  @override
  Future<double?> saldo(String cuenta) async => 500000;
  @override
  Future<TransferenciaResponse> transferir(String o, String d, double m) async => TransferenciaResponse(
      false, mensajeParaEstado(401),
      statusCode: 401, sesionExpirada: true);
}

Future<void> _login(WidgetTester t) async {
  await t.enterText(find.byKey(const Key('correo')), 'julia@nexora.co');
  await t.enterText(find.byKey(const Key('clave')), 'clave123');
  await t.tap(find.byKey(const Key('ingresar')));
  await t.pumpAndSettle();
}

Future<void> _transferir(WidgetTester t, String destino, String monto) async {
  await t.tap(find.text('Nueva transferencia'));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('destino')), destino);
  await t.enterText(find.byKey(const Key('monto')), monto);
  await t.tap(find.byKey(const Key('enviar')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('NEXO-121: flujo login → transferencia → saldo actualizado → cerrar sesión', (t) async {
    await t.pumpWidget(NexoraApp(api: MockTransferenciaApi()));
    await _login(t);
    expect(find.text('\$500.000 COP'), findsOneWidget);
    await _transferir(t, '200001', '150000');
    expect(find.textContaining('NEX-TRX-000001'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('\$350.000 COP'), findsOneWidget);
    await t.tap(find.byKey(const Key('salir')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ingresar')), findsOneWidget);
  });

  testWidgets('NEXO-77: el login valida correo y contraseña antes de entrar', (t) async {
    await t.pumpWidget(NexoraApp(api: MockTransferenciaApi()));
    await t.tap(find.byKey(const Key('ingresar')));
    await t.pumpAndSettle();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(find.text('Mínimo 4 caracteres'), findsOneWidget);
    expect(find.text('Nueva transferencia'), findsNothing);
  });

  testWidgets('NEXO-77/122: sesión expirada (401) cierra sesión y vuelve al login', (t) async {
    await t.pumpWidget(NexoraApp(api: _ApiSesionVencida()));
    await _login(t);
    await _transferir(t, '200001', '1000');
    expect(find.byKey(const Key('ingresar')), findsOneWidget);
    expect(find.textContaining('sesión expiró'), findsOneWidget);
  });

  testWidgets('NEXO-78: rechazo de Shield (403) muestra el mensaje y el código', (t) async {
    await t.pumpWidget(NexoraApp(api: MockTransferenciaApi()));
    await _login(t);
    await _transferir(t, '300001', '1000');
    expect(find.textContaining('NEXORA Shield'), findsOneWidget);
    expect(find.textContaining('Código: 403'), findsOneWidget);
  });

  testWidgets('NEXO-78: Shield no disponible (503) muestra el mensaje y el código', (t) async {
    await t.pumpWidget(NexoraApp(api: MockTransferenciaApi()));
    await _login(t);
    await _transferir(t, '300002', '1000');
    expect(find.textContaining('no disponible'), findsOneWidget);
    expect(find.textContaining('Código: 503'), findsOneWidget);
  });
}
