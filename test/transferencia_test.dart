import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/api.dart';
import 'package:nexora_app/main.dart';

Future<void> _transferir(WidgetTester t, MockTransferenciaApi api, String destino, String monto) async {
  await t.pumpWidget(MaterialApp(home: TransferScreen(api: api, cuentaOrigen: '100001')));
  await t.enterText(find.byKey(const Key('destino')), destino);
  await t.enterText(find.byKey(const Key('monto')), monto);
  await t.tap(find.byKey(const Key('enviar')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('TEST-01 / CA-01: transferencia exitosa muestra comprobante y descuenta saldo', (t) async {
    final api = MockTransferenciaApi();
    await _transferir(t, api, '200001', '150000');
    expect(find.textContaining('NEX-TRX-000001'), findsOneWidget);
    expect(await api.saldo('100001'), 350000);
  });

  testWidgets('TEST-02 / CA-02: saldo insuficiente rechaza y conserva saldo', (t) async {
    final api = MockTransferenciaApi();
    await _transferir(t, api, '200001', '900000');
    expect(find.textContaining('Saldo insuficiente'), findsOneWidget);
    expect(await api.saldo('100001'), 500000);
  });

  testWidgets('TEST-03 / CA-03: cuenta destino inválida rechaza y conserva saldo', (t) async {
    final api = MockTransferenciaApi();
    await _transferir(t, api, '999999', '50000');
    expect(find.textContaining('Cuenta destino inválida'), findsOneWidget);
    expect(await api.saldo('100001'), 500000);
  });
}
