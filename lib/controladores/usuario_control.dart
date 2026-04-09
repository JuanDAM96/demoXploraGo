import 'package:flutter/foundation.dart';
import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';

class UsuarioControl extends ChangeNotifier {
  final UsuarioServicio _servicio = UsuarioServicio();

  Usuario? _usuarioActual;
  bool _cargando = false;
  String? _error;

  // Getters
  Usuario? get usuarioActual => _usuarioActual;
  bool get cargando => _cargando;
  String? get error => _error;

  // Cargar usuario por ID
  Future<void> cargarUsuario(String usuarioId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      _usuarioActual = await _servicio.obtenerPorId(usuarioId);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
    }
  }

  // Actualizar perfil
  Future<void> actualizarPerfil({
    required String usuarioId,
    String? nombre,
    String? apellidos,
    String? nombreUsuario,
    String? telefono,
    String? direccion,
    String? numero,
    String? localidad,
    String? provincia,
    String? codigoPostal,
    String? fechaNacimiento,
  }) async {
    try {
      _error = null;
      final Usuario actualizado = await _servicio.actualizarPerfil(
        usuarioId: usuarioId,
        nombre: nombre,
        apellidos: apellidos,
        nombreUsuario: nombreUsuario,
        telefono: telefono,
        direccion: direccion,
        numero: numero,
        localidad: localidad,
        provincia: provincia,
        codigoPostal: codigoPostal,
        fechaNacimiento: fechaNacimiento,
      );

      _usuarioActual = actualizado;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar solo el nombre de usuario
  Future<void> actualizarNombreUsuario(String usuarioId, String nuevoNombre) async {
    try {
      _error = null;
      final Usuario actualizado = await _servicio.actualizarPerfil(
        usuarioId: usuarioId,
        nombreUsuario: nuevoNombre,
      );

      _usuarioActual = actualizado;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Obtener usuario por nombre de usuario
  Future<Usuario?> buscarPorNombreUsuario(String nombreUsuario) async {
    try {
      _error = null;
      return await _servicio.obtenerPorNombreUsuario(nombreUsuario);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Es el usuario actual
  bool esUsuarioActual(String usuarioId) {
    return _usuarioActual?.id == usuarioId;
  }

  // Limpiar estado
  void limpiar() {
    _usuarioActual = null;
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
