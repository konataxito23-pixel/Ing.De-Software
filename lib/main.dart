import 'package:flutter/material.dart';

import 'api.dart';

const _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:5000');

void main() {
  runApp(
    NexoraApp(
      api: _useMock ? MockTransferenciaApi() : HttpTransferenciaApi(_baseUrl),
    ),
  );
}

String _cop(double v) =>
    '\$${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} COP';

InputDecoration _dec(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.api});
  final TransferenciaApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final TransferenciaApi api;

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController(text: 'ana');
  final _password = TextEditingController(text: '1234');

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.api.login(_usuario.text.trim(), _password.text.trim());
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(api: widget.api)),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  Text(
                    'NEXORA',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usuario,
                    decoration: _dec('Usuario'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: _dec('Contraseña'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ingresar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});
  final TransferenciaApi api;

  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _cuentas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCuentas();
  }

  Future<void> _loadCuentas() async {
    setState(() => _loading = true);
    try {
      final cuentas = await widget.api.cuentas();
      if (!mounted) return;
      setState(() {
        _cuentas = cuentas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXORA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.api.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            for (final cuenta in _cuentas)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(cuenta['alias'] ?? 'Cuenta'),
                  subtitle: Text('Cuenta ${cuenta['numero']}'),
                  trailing: Text(_cop((cuenta['saldo'] as num).toDouble())),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransferScreen(
                          api: widget.api,
                          cuentaOrigen: (cuenta['numero'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Nueva transferencia'),
              onPressed: () async {
                if (_cuentas.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransferScreen(
                        api: widget.api,
                        cuentaOrigen: _cuentas.first['numero'].toString(),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
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

    try {
      final response = await widget.api.transferir(
        origen: widget.cuentaOrigen,
        destino: _destino.text.trim(),
        monto: double.parse(_monto.text.trim()),
      );

      setState(() {
        _cargando = false;
        _res = response;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _res = TransferenciaResponse(
          exitosa: false,
          mensaje: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _res;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transferencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  initialValue: widget.cuentaOrigen,
                  enabled: false,
                  decoration: _dec('Cuenta origen'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destino,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Cuenta destino'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Cuenta destino requerida' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _monto,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('Monto (COP)'),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').trim());
                    return (value == null || value <= 0) ? 'Monto inválido' : null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _cargando ? null : _enviar,
                    child: _cargando
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text('Transferir'),
                  ),
                ),
              ],
            ),
          ),
          if (result != null)
            Card(
              margin: const EdgeInsets.only(top: 20),
              color: result.exitosa ? Colors.green.shade50 : Colors.red.shade50,
              child: ListTile(
                leading: Icon(
                  result.exitosa ? Icons.check_circle : Icons.error,
                  color: result.exitosa ? Colors.green : Colors.red,
                ),
                title: Text(result.exitosa ? 'Transferencia exitosa' : 'Transferencia rechazada'),
                subtitle: Text(result.mensaje),
              ),
            ),
        ],
      ),
    );
  }
}
