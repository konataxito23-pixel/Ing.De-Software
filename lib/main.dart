import 'package:flutter/material.dart';
import 'api.dart';
import 'sesion.dart';

const _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

const _fondo = Color(0xFF040B1A);
const _tarjeta = Color(0xFF0A1830);
const _linea = Color(0xFF16335C);
const _azul = Color(0xFF1E8BFF);
const _verde = Color(0xFF2DE0B5);
const _rojo = Color(0xFFFF6B7F);
const _suave = Color(0xFF9FB3D1);
const _icono = Color(0xFF8CC8FF);

void main() => runApp(NexoraApp(api: _useMock ? MockTransferenciaApi() : HttpTransferenciaApi(_baseUrl)));

String _peso(double v) =>
    '\$ ${v.abs().round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

InputDecoration _dec(String label) => InputDecoration(labelText: label);

BoxDecoration _caja([Gradient? g]) => BoxDecoration(
      color: g == null ? _tarjeta : null,
      gradient: g,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _linea),
    );

class _Ondas extends CustomPainter {
  const _Ondas();
  @override
  void paint(Canvas c, Size s) {
    final sh = const LinearGradient(colors: [Color(0x0022D3EE), Color(0xFF22D3EE), Color(0xFF1E6BFF)])
        .createShader(Offset.zero & s);
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.80 - i * 0.07);
      final p = Path()
        ..moveTo(0, y)
        ..cubicTo(s.width * .35, y + s.height * .15, s.width * .60, y - s.height * .55, s.width, y - s.height * .25);
      c.drawPath(p, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - i * .6
        ..shader = sh);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();
  @override
  void paint(Canvas c, Size s) {
    Paint t(Color col) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = col;
    Path w(double dy) => Path()
      ..moveTo(4, s.height * .45 + dy)
      ..cubicTo(s.width * .3, -4 + dy, s.width * .5, s.height * .9 + dy, s.width - 4, s.height * .3 + dy);
    c.drawPath(w(6), t(const Color(0xFF1E6BFF)));
    c.drawPath(w(-2), t(const Color(0xFF22D3EE)));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 46, height: 26, child: CustomPaint(painter: _LogoPainter())),
        SizedBox(width: 10),
        Text('NEXORA', style: TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w500)),
      ]);
}

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
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: _azul, brightness: Brightness.dark),
          scaffoldBackgroundColor: _fondo,
          appBarTheme: const AppBarTheme(backgroundColor: _fondo, elevation: 0),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: _tarjeta,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _linea)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _azul,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        builder: (_, child) => ColoredBox(
          color: _fondo,
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child)),
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
            child: Form(
              key: _form,
              child: Column(children: [
                const _Logo(),
                const SizedBox(height: 8),
                const Text('Tu futuro financiero, en tus manos.', style: TextStyle(color: _suave)),
                const SizedBox(height: 32),
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
  late Future<double?> _saldo;
  late Future<List<Movimiento>> _movs;
  bool _ver = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _saldo = widget.api.saldo(_cuenta);
    _movs = widget.api.movimientos(_cuenta);
  }

  void _pronto(String f) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$f: próximamente')));

  Future<void> _transferir() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TransferScreen(api: widget.api, cuentaOrigen: _cuenta, sesion: widget.sesion)));
    if (mounted) setState(_cargar);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
            Row(children: [
              const _Logo(),
              const Spacer(),
              PopupMenuButton<String>(
                key: const Key('perfil'),
                tooltip: 'Perfil',
                color: _tarjeta,
                onSelected: (_) => widget.sesion.cerrar(),
                itemBuilder: (_) => const [PopupMenuItem(key: Key('salir'), value: 'salir', child: Text('Cerrar sesión'))],
                child: const CircleAvatar(radius: 22, backgroundColor: _tarjeta, child: Icon(Icons.person_outline)),
              ),
            ]),
            SizedBox(
              height: 150,
              child: Stack(children: [
                const Positioned.fill(child: CustomPaint(painter: _Ondas())),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hola, ${widget.sesion.nombre}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Tu futuro financiero, en tus manos.', style: TextStyle(color: _suave, fontSize: 16)),
                  ]),
                ),
              ]),
            ),
            Container(
              decoration: _caja(const LinearGradient(
                  colors: [Color(0xFF0E2D5E), Color(0xFF071A38)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(children: [
                  const Positioned.fill(child: Opacity(opacity: .7, child: CustomPaint(painter: _Ondas()))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('Cuenta Corriente', style: TextStyle(fontSize: 18)),
                        const Spacer(),
                        IconButton(
                          key: const Key('ojo'),
                          tooltip: _ver ? 'Ocultar saldo' : 'Mostrar saldo',
                          onPressed: () => setState(() => _ver = !_ver),
                          icon: Icon(_ver ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ]),
                      Text('•••• ${_cuenta.substring(2)}', style: const TextStyle(color: _suave)),
                      const SizedBox(height: 8),
                      FutureBuilder<double?>(
                        future: _saldo,
                        builder: (_, s) => Text(
                            s.data == null ? 'Saldo no disponible' : (_ver ? _peso(s.data!) : '\$ ••••••'),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      ),
                      const Text('Disponible', style: TextStyle(color: _suave)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Accion(key: const Key('accion-transferir'), icono: Icons.swap_horiz, texto: 'Transferir', onTap: _transferir),
              _Accion(icono: Icons.qr_code_scanner, texto: 'QR\nPagar', onTap: () => _pronto('QR Pagar')),
              _Accion(icono: Icons.credit_card, texto: 'Tarjetas', onTap: () => _pronto('Tarjetas')),
              _Accion(icono: Icons.savings_outlined, texto: 'Ahorrar', onTap: () => _pronto('Ahorrar')),
              _Accion(icono: Icons.more_horiz, texto: 'Más', onTap: () => _pronto('Más')),
            ]),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _caja(),
              child: Column(children: [
                Row(children: [
                  const Text('Movimientos recientes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => _pronto('Ver todos'), child: const Text('Ver todos ›', style: TextStyle(color: _azul))),
                ]),
                const SizedBox(height: 8),
                FutureBuilder<List<Movimiento>>(
                  future: _movs,
                  builder: (_, s) {
                    final l = s.data ?? const <Movimiento>[];
                    if (l.isEmpty) {
                      return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Sin movimientos para mostrar', style: TextStyle(color: _suave)));
                    }
                    return Column(children: [for (final m in l.take(4)) _Fila(m)]);
                  },
                ),
              ]),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: () => _pronto('Tu tarjeta Nexora'),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _caja(const LinearGradient(colors: [Color(0xFF0A2149), Color(0xFF1C4FBF)])),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tu tarjeta Nexora', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text('Más que una tarjeta, es tu aliada en cada paso.', style: TextStyle(color: _suave)),
                      SizedBox(height: 10),
                      Text('Conoce más →', style: TextStyle(color: Color(0xFF5CC8FF))),
                    ]),
                  ),
                  Transform.rotate(
                    angle: -.35,
                    child: Container(
                      width: 96,
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFF0B1730), Color(0xFF1B3F8F)]),
                        border: Border.all(color: _linea),
                      ),
                      child: const Icon(Icons.waves, color: Color(0xFF22D3EE)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: Color(0xFF071226), border: Border(top: BorderSide(color: _linea))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(children: [
                const Expanded(child: _Tab(Icons.home_filled, 'Inicio', activo: true)),
                Expanded(child: _Tab(Icons.bar_chart, 'Finanzas', onTap: () => _pronto('Finanzas'))),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      key: const Key('centro'),
                      onTap: _transferir,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFF22A6FF), Color(0xFF1E4FD8)])),
                        child: const Icon(Icons.waves, size: 30, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _Tab(Icons.verified_user_outlined, 'Seguridad', onTap: () => _pronto('Seguridad'))),
                Expanded(child: _Tab(Icons.grid_view, 'Más', onTap: () => _pronto('Más'))),
              ]),
            ),
          ),
        ),
      );
}

class _Accion extends StatelessWidget {
  const _Accion({super.key, required this.icono, required this.texto, required this.onTap});
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: 62,
          child: Column(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0C2347), border: Border.all(color: _linea)),
              child: Icon(icono, color: _icono),
            ),
            const SizedBox(height: 8),
            Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
          ]),
        ),
      );
}

class _Tab extends StatelessWidget {
  const _Tab(this.icono, this.texto, {this.activo = false, this.onTap});
  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, color: activo ? _azul : _suave),
          const SizedBox(height: 4),
          Text(texto, style: TextStyle(fontSize: 12, color: activo ? _azul : _suave)),
        ]),
      );
}

class _Fila extends StatelessWidget {
  const _Fila(this.m);
  final Movimiento m;
  @override
  Widget build(BuildContext context) {
    final pos = m.monto >= 0;
    final icono = switch (m.tipo) {
      TipoMov.recibida => Icons.arrow_upward,
      TipoMov.enviada || TipoMov.pago => Icons.arrow_downward,
      TipoMov.tarjeta => Icons.credit_card,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0C2347), border: Border.all(color: _linea)),
          child: Icon(icono, size: 22, color: m.tipo == TipoMov.tarjeta ? _icono : (pos ? _verde : _rojo)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.titulo, style: const TextStyle(fontSize: 16)),
            Text(m.detalle, style: const TextStyle(color: _suave, fontSize: 13)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${pos ? '+' : '-'} ${_peso(m.monto)}',
              style: TextStyle(color: pos ? _verde : null, fontWeight: FontWeight.w600)),
          Text(m.fecha, style: const TextStyle(color: _suave, fontSize: 12)),
        ]),
      ]),
    );
  }
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
          Container(
            key: const Key('resultado'),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: r.exitosa ? const Color(0x2616C784) : const Color(0x26FF5A6E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: r.exitosa ? _verde : _rojo),
            ),
            child: ListTile(
              leading: Icon(r.exitosa ? Icons.check_circle : Icons.error, color: r.exitosa ? _verde : _rojo),
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
