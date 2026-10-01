import 'package:flutter/material.dart';
import 'api.dart';

const _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

void main() => runApp(NexoraApp(api: _useMock ? MockTransferenciaApi() : HttpTransferenciaApi(_baseUrl)));

String _cop(double v) =>
    '\$${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} COP';

InputDecoration _dec(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.api});
  final TransferenciaApi api;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NEXORA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1E4FD8),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          useMaterial3: true,
        ),
        home: LoginScreen(api: api),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final TransferenciaApi api;
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _form,
                child: Column(children: [
                  Text('NEXORA',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextFormField(decoration: _dec('Correo'), validator: _req),
                  const SizedBox(height: 12),
                  TextFormField(decoration: _dec('Contraseña'), obscureText: true, validator: _req),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (_) => DashboardScreen(api: widget.api)));
                      }
                    },
                    child: const Text('Ingresar'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});
  final TransferenciaApi api;
  @override
  State<DashboardScreen> createState() => _DashState();
}

class _DashState extends State<DashboardScreen> {
  static const _cuenta = '100001';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('NEXORA')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cuenta de ahorros $_cuenta'),
                const SizedBox(height: 8),
                FutureBuilder<double?>(
                  future: widget.api.saldo(_cuenta),
                  builder: (_, s) => Text(s.data == null ? 'Saldo no disponible' : _cop(s.data!),
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Nueva transferencia'),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TransferScreen(api: widget.api, cuentaOrigen: _cuenta)));
              setState(() {});
            },
          ),
        ]),
      );
}

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.api, required this.cuentaOrigen});
  final TransferenciaApi api;
  final String cuentaOrigen;
  @override
  State<TransferScreen> createState() => _TransferState();
}

class _TransferState extends State<TransferScreen> {
  final _form = GlobalKey<FormState>();
  final _destino = TextEditingController();
  final _monto = TextEditingController();
  bool _cargando = false;
  TransferenciaResponse? _res;

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _res = null;
    });
    final r = await widget.api.transferir(widget.cuentaOrigen, _destino.text.trim(), double.parse(_monto.text.trim()));
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _res = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _res;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transferencia')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Form(
          key: _form,
          child: Column(children: [
            TextFormField(initialValue: widget.cuentaOrigen, enabled: false, decoration: _dec('Cuenta origen')),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('destino'),
              controller: _destino,
              keyboardType: TextInputType.number,
              decoration: _dec('Cuenta destino'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la cuenta destino' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('monto'),
              controller: _monto,
              keyboardType: TextInputType.number,
              decoration: _dec('Monto (COP)'),
              validator: (v) {
                final m = double.tryParse((v ?? '').trim());
                return (m == null || m <= 0) ? 'Ingresa un monto mayor que cero' : null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('enviar'),
                onPressed: _cargando ? null : _enviar,
                child: _cargando
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Transferir'),
              ),
            ),
          ]),
        ),
        if (r != null)
          Card(
            key: const Key('resultado'),
            margin: const EdgeInsets.only(top: 20),
            color: r.exitosa ? Colors.green.shade50 : Colors.red.shade50,
            child: ListTile(
              leading: Icon(r.exitosa ? Icons.check_circle : Icons.error,
                  color: r.exitosa ? Colors.green : Colors.red),
              title: Text(r.exitosa ? 'Transferencia exitosa' : 'Transferencia rechazada'),
              subtitle: Text(r.exitosa ? '${r.mensaje}\nComprobante: ${r.comprobante}' : r.mensaje),
            ),
          ),
      ]),
    );
  }
}
