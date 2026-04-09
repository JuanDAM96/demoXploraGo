import 'package:flutter/foundation.dart';
import 'package:xplorago/modelo/grupo.dart';
import 'package:xplorago/nucleo/servicios/grupo_servicio.dart';

class GrupoControl extends ChangeNotifier {
  final GrupoServicio _servicio = GrupoServicio();

  List<Grupo> _grupos = <Grupo>[];
  Grupo? _grupoActual;
  bool _cargando = false;
  String? _error;

  // Getters
  List<Grupo> get grupos => _grupos;
  Grupo? get grupoActual => _grupoActual;
  bool get cargando => _cargando;
  String? get error => _error;

  // Cargar todos los grupos del usuario
  Future<void> cargarGrupos(String usuarioId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      _grupos = await _servicio.obtenerPorUsuario(usuarioId);

      if (_grupos.isEmpty) {
        _grupoActual = null;
      } else if (_grupoActual != null &&
          !_grupos.any((Grupo grupo) => grupo.id == _grupoActual!.id)) {
        _grupoActual = null;
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
    }
  }

  // Seleccionar grupo actual
  Future<void> seleccionarGrupo(String grupoId) async {
    try {
      _error = null;
      _grupoActual = await _servicio.obtenerPorId(grupoId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Crear nuevo grupo
  Future<void> crearGrupo({
    required String nombre,
    String? destino,
    String? descripcion,
    required String creadorId,
  }) async {
    try {
      _error = null;
      final Grupo grupo = await _servicio.crear(
        nombre: nombre,
        destino: destino,
        descripcion: descripcion,
        creadorId: creadorId,
      );

      _grupos.add(grupo);
      _grupoActual = grupo;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar grupo
  Future<void> actualizar(Grupo grupo) async {
    try {
      _error = null;
      final Grupo actualizado = await _servicio.actualizar(grupo);

      final int indice = _grupos.indexWhere((g) => g.id == actualizado.id);
      if (indice != -1) {
        _grupos[indice] = actualizado;
      }

      if (_grupoActual?.id == actualizado.id) {
        _grupoActual = actualizado;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar grupo
  Future<void> eliminar(String grupoId) async {
    try {
      _error = null;
      await _servicio.eliminar(grupoId);

      _grupos.removeWhere((g) => g.id == grupoId);

      if (_grupoActual?.id == grupoId) {
        _grupoActual = null;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Agregar miembro al grupo
  Future<void> agregarMiembro(String grupoId, String usuarioId) async {
    try {
      _error = null;
      await _servicio.agregarMiembro(grupoId, usuarioId);

      if (_grupoActual?.id == grupoId) {
        await seleccionarGrupo(grupoId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar miembro del grupo
  Future<void> eliminarMiembro(String grupoId, String usuarioId) async {
    try {
      _error = null;
      await _servicio.eliminarMiembro(grupoId, usuarioId);

      if (_grupoActual?.id == grupoId) {
        await seleccionarGrupo(grupoId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Obtener IDs de miembros del grupo
  Future<List<String>> obtenerMiembroIds(String grupoId) async {
    try {
      return await _servicio.obtenerMiembroIds(grupoId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Limpiar estado
  void limpiar() {
    _grupos = <Grupo>[];
    _grupoActual = null;
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
