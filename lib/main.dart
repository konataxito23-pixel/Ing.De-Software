import 'package:flutter/material.dart';
import 'api.dart';
import 'sesion.dart';

const _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

void main() => runApp(NexoraApp(api: _useMock ? MockTransferenciaApi() : HttpTransferenciaApi(_baseUrl)));

String _cop(double v) =>
    '\$${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} COP';

InputDecoration _dec(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());

class NexoraApp extends StatefulWidget {
  const NexoraApp({super.key, required this.api});
  final TransferenciaApi api;
  @override
  State<NexoraApp> createState() => _NexoraAppState();
}

class _NexoraAppState extends State<NexoraApp> {
  final _sesion = SesionController();

  @override
  void dispose() {
    _sesion.dispose();
    super.dispose();
  }

  // Sin sesión activa solo se puede ver el login (NEXO-77).
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NEXORA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1E4FD8),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          useMaterial3: true,
        ),
        home: ListenableBuilder(
          listenable: _sesion,
          builder: (_, __) => _sesion.activa
              ? DashboardScreen(api: widget.api, sesion: _sesion)
              : LoginScreen(sesion: _sesion),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.sesion});
  final SesionController sesion;
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();

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
                  TextFormField(
                    key: const Key('correo'),
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Correo'),
                    validator: (v) => (v ?? '').contains('@') ? null : 'Ingresa un correo válido',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('clave'),
                    decoration: _dec('Contraseña'),
                    obscureText: true,
                    validator: (v) => (v ?? '').length >= 4 ? null : 'Mínimo 4 caracteres',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('ingresar'),
                      onPressed: () {
                        if (_form.currentState!.validate()) widget.sesion.iniciar(_correo.text.trim());
                      },
                      child: const Text('Ingresar'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api, required this.sesion});
  final TransferenciaApi api;
  final SesionController sesion;
  @override
  State<DashboardScreen> createState() => _DashState();
}

class _DashState extends State<DashboardScreen> {
  static const _cuenta = '100001';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('NEXORA'),
          actions: [
            IconButton(
              key: const Key('salir'),
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: widget.sesion.cerrar,
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Hola, ${widget.sesion.usuario}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
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
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          TransferScreen(api: widget.api, cuentaOrigen: _cuenta, sesion: widget.sesion)));
              if (mounted) setState(() {});
            },
          ),
        ]),
      );
}

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.api, required this.cuentaOrigen, this.sesion});
  final TransferenciaApi api;
  final String cuentaOrigen;
  final SesionController? sesion;
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
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _cargando = true;
      _res = null;
    });
    final r = await widget.api.transferir(widget.cuentaOrigen, _destino.text.trim(), double.parse(_monto.text.trim()));
    if (!mounted) return;
    if (r.sesionExpirada && widget.sesion != null) {
      widget.sesion!.cerrar();
      nav.popUntil((route) => route.isFirst);
      messenger.showSnackBar(SnackBar(content: Text(r.mensaje)));
      return;
    }
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
              subtitle: Text(r.exitosa
                  ? '${r.mensaje}\nComprobante: ${r.comprobante}'
                  : '${r.mensaje}${r.statusCode == null ? '' : '\nCódigo: ${r.statusCode}'}'),
            ),
          ),
      ]),
    );
  }
}
