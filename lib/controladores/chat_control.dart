import 'package:flutter/foundation.dart';
import 'package:xplorago/modelo/mensaje.dart';
import 'package:xplorago/nucleo/servicios/mensaje_servicio.dart';

class ChatControl extends ChangeNotifier {
  final MensajeServicio _servicio = MensajeServicio();

  List<Mensaje> _mensajes = <Mensaje>[];
  bool _cargando = false;
  String? _error;

  // Getters
  List<Mensaje> get mensajes => _mensajes;
  bool get cargando => _cargando;
  String? get error => _error;

  // Cargar mensajes de un grupo
  Future<void> cargarMensajesPorGrupo(String grupoId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      _mensajes = await _servicio.obtenerPorGrupo(grupoId);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
    }
  }

  // Enviar nuevo mensaje
  Future<void> enviarMensaje({
    required String grupoId,
    required String usuarioId,
    required String texto,
  }) async {
    try {
      _error = null;
      final Mensaje mensaje = await _servicio.crear(
        grupoId: grupoId,
        usuarioId: usuarioId,
        texto: texto,
      );

      _mensajes.add(mensaje);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Marcar mensaje como leído
  Future<void> marcarComoLeido(String mensajeId) async {
    try {
      _error = null;
      final Mensaje mensaje = _mensajes.firstWhere((m) => m.id == mensajeId);
      final Mensaje actualizado = mensaje.copyWith(leido: true);

      await _servicio.marcarComoLeido(mensajeId);

      final int indice = _mensajes.indexWhere((m) => m.id == mensajeId);
      if (indice != -1) {
        _mensajes[indice] = actualizado;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Marcar todos como leídos
  Future<void> marcarTodosComoLeidos() async {
    try {
      _error = null;

      for (final mensaje in _mensajes.where((m) => !m.leido)) {
        await marcarComoLeido(mensaje.id);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Eliminar mensaje
  Future<void> eliminar(String mensajeId) async {
    try {
      _error = null;
      await _servicio.eliminar(mensajeId);

      _mensajes.removeWhere((m) => m.id == mensajeId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Obtener mensajes no leídos
  List<Mensaje> obtenerNoLeidos() {
    return _mensajes.where((m) => !m.leido).toList();
  }

  // Obtener mensajes de un usuario
  List<Mensaje> obtenerDelUsuario(String usuarioId) {
    return _mensajes.where((m) => m.usuarioId == usuarioId).toList();
  }

  // Limpiar estado
  void limpiar() {
    _mensajes = <Mensaje>[];
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
