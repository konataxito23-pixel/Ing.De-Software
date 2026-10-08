import 'package:flutter/foundation.dart';

/// Estado de sesión en memoria (NEXO-77). No hay backend de autenticación todavía.
class SesionController extends ChangeNotifier {
  String? _usuario;
  String? get usuario => _usuario;
  bool get activa => _usuario != null;

  void iniciar(String usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrar() {
    _usuario = null;
    notifyListeners();
  }
}
