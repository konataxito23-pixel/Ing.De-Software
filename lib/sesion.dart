import 'package:flutter/foundation.dart';

/// Estado de sesión en memoria (NEXO-77). No hay backend de autenticación todavía.
class SesionController extends ChangeNotifier {
  String? _usuario;
  String? get usuario => _usuario;
  bool get activa => _usuario != null;

  /// Nombre para el saludo: parte local del correo con la primera letra en mayúscula.
  String get nombre {
    final n = (_usuario ?? '').split('@').first;
    return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
  }

  void iniciar(String usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrar() {
    _usuario = null;
    notifyListeners();
  }
}
