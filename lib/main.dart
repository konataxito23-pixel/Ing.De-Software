import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api.dart';

const _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000',
);

void main() => runApp(
  NexoraApp(
    api: _useMock ? MockTransferenciaApi() : HttpTransferenciaApi(_baseUrl),
  ),
);

String _cop(double v) =>
    '\$${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} COP';

InputDecoration _dec(String label) => InputDecoration(
  labelText: label,
  border: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  ),
  filled: true,
  fillColor: Colors.white.withOpacity(0.08),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  enabledBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: Color(0xFF9AA9C4), width: 1.2),
  ),
  focusedBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: Color(0xFF74D6FF), width: 1.6),
  ),
  labelStyle: const TextStyle(color: Color(0xFFEFF5FF), fontSize: 14),
);

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key, required this.api});
  final TransferenciaApi api;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NEXORA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF061A2F),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B6DE1),
            brightness: Brightness.dark,
          ),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
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
  final _email = TextEditingController(text: 'ana@nexora.com');
  final _password = TextEditingController(text: '123456');
  bool _cargando = false;
  String? _error;

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    final ok = await widget.api.login(_email.text, _password.text);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _cargando = false;
        _error = 'Credenciales inválidas';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(api: widget.api)),
    );

    setState(() {
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDDE6ED),
              Color(0xFFF4F6FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _browserBar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.only(top: 28, bottom: 20),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              'NEXORA',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1E1E),
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: 360,
                              child: TextFormField(
                                controller: _email,
                                decoration: _dec('Correo').copyWith(
                                  hintText: 'ana@nexora.com',
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF8E97A8), width: 1.1),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF7AA7CE), width: 1.4),
                                  ),
                                ),
                                validator: _req,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Color(0xFF1E1E1E)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 360,
                              child: TextFormField(
                                controller: _password,
                                decoration: _dec('Contraseña').copyWith(
                                  hintText: '••••••',
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF8E97A8), width: 1.1),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF7AA7CE), width: 1.4),
                                  ),
                                ),
                                obscureText: true,
                                validator: _req,
                                style: const TextStyle(color: Color(0xFF1E1E1E)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 360,
                              height: 52,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B5F8A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _cargando ? null : _login,
                                child: _cargando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Ingresar',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
  State<DashboardScreen> createState() => _DashState();
}

class _DashState extends State<DashboardScreen> {
  static const _cuenta = '100001';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06172E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF040B16),
              Color(0xFF071E36),
              Color(0xFF071A2C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _browserBarDark(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _shieldBadge(size: 28),
                              const SizedBox(width: 10),
                              const Text(
                                'NEXORA',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFFEAF6FF),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Hola, Julia',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tu futuro financiero, en tus manos.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB4C5D9),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: CustomPaint(
                              painter: _WavePainter(),
                              child: const SizedBox(height: 38, width: 420),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: 420,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A3F6D), Color(0xFF112B50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Cuenta Corriente',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFFEAF4FF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: const Color(0xFF8BCFF9), width: 1.2),
                                      ),
                                      child: const Icon(
                                        Icons.visibility_outlined,
                                        size: 16,
                                        color: Color(0xFF8BCFF9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '•••• 0001',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFFDEEAF8),
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FutureBuilder<double?>(
                                  future: widget.api.saldo(_cuenta),
                                  builder: (_, s) => Text(
                                    s.data == null ? 'Saldo no disponible' : _cop(s.data!),
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Disponible',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFB9D5F5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _actionTile(Icons.swap_horiz_outlined, 'Transferir'),
                              _actionTile(Icons.qr_code_2, 'QR\nPagar'),
                              _actionTile(Icons.credit_card, 'Tarjetas'),
                              _actionTile(Icons.savings_outlined, 'Ahorrar'),
                              _actionTile(Icons.more_horiz, 'Más'),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: 420,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2140),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Movimientos recientes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Ver todos',
                                      style: TextStyle(
                                        color: Color(0xFF7BC4FF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _movementRow(
                                  icon: Icons.arrow_upward_rounded,
                                  title: 'Transferencia recibida',
                                  subtitle: 'Karla Restrepo',
                                  amount: '+ \$250.000',
                                  time: 'Hoy, 08:42',
                                  positive: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 420,
                            padding: const EdgeInsets.only(top: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _bottomNav('Inicio', Icons.home),
                                _bottomNav('Finanzas', Icons.bar_chart_rounded),
                                _bottomNav('Seguridad', Icons.shield_outlined),
                                _bottomNav('Más', Icons.apps_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1B467D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8ED9FF).withOpacity(0.35)),
            ),
            child: Icon(icon, color: const Color(0xFF80D9FF), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFDADFF2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7BC4FF), size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFDBE7FF)),
        ),
      ],
    );
  }

  Widget _movementRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    required bool positive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1B447F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: positive ? const Color(0xFF7BFFB4) : Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB3C5E1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFFB3C5E1),
                  fontSize: 12,
                ),
              ),
            ],
          ),
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

Widget _browserBar() {
  return Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: const BoxDecoration(
      color: Color(0xFFE9EBEF),
      border: Border(bottom: BorderSide(color: Color(0xFFD7DCE2))),
    ),
    child: Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1A8CFF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF5B6470)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Text(
              'localhost:59637',
              style: TextStyle(color: Color(0xFF4A515E), fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.star_border_rounded, color: Color(0xFF4A515E)),
        const SizedBox(width: 12),
        const Icon(Icons.more_vert_rounded, color: Color(0xFF4A515E)),
      ],
    ),
  );
}

Widget _browserBarDark() {
  return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF011B33), Color(0xFF050D1E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      border: Border(bottom: BorderSide(color: Color(0xFF3F638C))),
    ),
    child: Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 14, color: Color(0xFF082942)),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.refresh, color: Color(0xFFB4C7D8), size: 18),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              'localhost:8080',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.star_border_rounded, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        const Icon(Icons.settings_outlined, color: Colors.white70, size: 18),
      ],
    ),
  );
}

Widget _shieldBadge({double size = 32}) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF7DE3FF), Color(0xFF3D8AF5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Color(0xFF2D9CDB),
          blurRadius: 12,
          offset: Offset(0, 4),
        )
      ],
    ),
    child: Center(
      child: Transform.rotate(
        angle: 0.9,
        child: Icon(
          Icons.shield_outlined,
          size: size * 0.62,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A84C9).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = Path();
    for (var i = 0; i < 6; i++) {
      final offset = i * 18.0;
      path.moveTo(0, size.height / 2 + offset * 0.2);
      for (var x = 0; x <= size.width; x += 16) {
        final y = size.height / 2 + offset * 0.2 + (x % 32 == 0 ? 4 : -4);
        path.lineTo(x.toDouble(), y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

