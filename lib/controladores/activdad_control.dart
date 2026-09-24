import 'package:flutter/foundation.dart';
import 'package:xplorago/modelo/actividad.dart';
import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/servicios/actividad_servicio.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';

class ActividadControl extends ChangeNotifier {
  final ActividadServicio _servicio = ActividadServicio();
  final UsuarioServicio _usuarioServicio = UsuarioServicio();

  List<Actividad> _actividades = <Actividad>[];
  final Map<String, bool> _asistenciaUsuario = <String, bool>{};
  final Map<String, List<String>> _apuntadoIdsPorActividad =
    <String, List<String>>{};
  final Map<String, List<String>> _apuntadosPorActividad =
      <String, List<String>>{};
  bool _cargando = false;
  String? _error;

  // Getters
  List<Actividad> get actividades => _actividades;
  Map<String, bool> get asistenciaUsuario =>
      Map<String, bool>.unmodifiable(_asistenciaUsuario);
  bool get cargando => _cargando;
  String? get error => _error;

  List<String> obtenerNombresApuntados(String actividadId) {
    return List<String>.unmodifiable(
      _apuntadosPorActividad[actividadId] ?? <String>[],
    );
  }

  List<String> obtenerIdsApuntados(String actividadId) {
    return List<String>.unmodifiable(
      _apuntadoIdsPorActividad[actividadId] ?? <String>[],
    );
  }

  // Método para cargar actividades de un grupo
  Future<void> cargarActividadesPorGrupo(String grupoId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      _actividades = await _servicio.obtenerPorGrupo(grupoId);
    _asistenciaUsuario.clear();
  _apuntadoIdsPorActividad.clear();
    _apuntadosPorActividad.clear();
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
    }
  }

  bool estaApuntadoEn(String actividadId) {
    return _asistenciaUsuario[actividadId] == true;
  }

  Future<void> cargarAsistenciaUsuario(String usuarioId) async {
    try {
      for (final Actividad actividad in _actividades) {
        final bool estaApuntado = await _servicio.obtenerEstadoAsistencia(
          actividadId: actividad.id,
          usuarioId: usuarioId,
        );
        _asistenciaUsuario[actividad.id] = estaApuntado;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> alternarAsistenciaUsuario({
    required String actividadId,
    required String usuarioId,
  }) async {
    try {
      _error = null;
      final bool nuevoEstado = await _servicio.alternarAsistencia(
        actividadId: actividadId,
        usuarioId: usuarioId,
      );
      _asistenciaUsuario[actividadId] = nuevoEstado;
      await refrescarApuntadosDeActividad(actividadId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarApuntadosDeTodasLasActividades() async {
    try {
      for (final Actividad actividad in _actividades) {
        await refrescarApuntadosDeActividad(actividad.id, notificar: false);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refrescarApuntadosDeActividad(
    String actividadId, {
    bool notificar = true,
  }) async {
    final List<String> ids = await _servicio.obtenerUsuarioIdsApuntados(
      actividadId,
    );
    _apuntadoIdsPorActividad[actividadId] = List<String>.from(ids);
    final List<String> nombres = <String>[];

    for (final String id in ids) {
      try {
        final Usuario usuario = await _usuarioServicio.obtenerPorId(id);
        final String nombre = _nombreVisibleUsuario(usuario, id);
        nombres.add(nombre);
      } catch (_) {
        nombres.add(id.substring(0, id.length >= 8 ? 8 : id.length));
      }
    }

    _apuntadosPorActividad[actividadId] = nombres;
    if (notificar) {
      notifyListeners();
    }
  }

  String _nombreVisibleUsuario(Usuario usuario, String fallbackId) {
    if (usuario.nombreUsuario?.trim().isNotEmpty == true) {
      return usuario.nombreUsuario!.trim();
    }
    if (usuario.nombre?.trim().isNotEmpty == true) {
      return usuario.nombre!.trim();
    }
    if (usuario.correo?.trim().isNotEmpty == true) {
      return usuario.correo!.split('@').first;
    }
    return fallbackId.substring(0, fallbackId.length >= 8 ? 8 : fallbackId.length);
  }

  // Crear nueva actividad
  Future<void> crearActividad({
    required String grupoId,
    required String titulo,
    String? descripcion,
    String? lugar,
    DateTime? fechaActividad,
    double? costo,
    String? creadoPor,
  }) async {
    try {
      _error = null;
      final Actividad nueva = await _servicio.crear(
        grupoId: grupoId,
        titulo: titulo,
        descripcion: descripcion,
        lugar: lugar,
        fechaActividad: fechaActividad,
        costo: costo,
        creadoPor: creadoPor,
      );

      _actividades.add(nueva);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar actividad
  Future<void> actualizar(Actividad actividad) async {
    try {
      _error = null;
      final Actividad actualizada = await _servicio.actualizar(actividad);

        final int indice = _actividades.indexWhere((a) => a.id == actualizada.id);
      if (indice != -1) {
        _actividades[indice] = actualizada;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Marcar como completada
  Future<void> marcarCompletada(String actividadId) async {
    try {
      _error = null;
      final int indice = _actividades.indexWhere((a) => a.id == actividadId);
      if (indice != -1) {
        final Actividad actual = _actividades[indice];
        final Actividad actualizada = actual.copyWith(completada: true);
        await actualizar(actualizada);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar actividad
  Future<void> eliminar(String actividadId) async {
    try {
      _error = null;
      await _servicio.eliminar(actividadId);

      _actividades.removeWhere((a) => a.id == actividadId);
    _asistenciaUsuario.remove(actividadId);
  _apuntadoIdsPorActividad.remove(actividadId);
    _apuntadosPorActividad.remove(actividadId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Filtrar por completadas
  List<Actividad> obtenerCompletas() {
    return _actividades.where((a) => a.completada).toList();
  }

  // Filtrar por pendientes
  List<Actividad> obtenerPendientes() {
    return _actividades.where((a) => !a.completada).toList();
  }

  // Filtrar por fecha próxima
  List<Actividad> obtenerProximas() {
    final ahora = DateTime.now();
    return _actividades
        .where((a) => a.fechaActividad != null && a.fechaActividad!.isAfter(ahora))
        .toList()
      ..sort((a, b) => (a.fechaActividad ?? DateTime.now())
          .compareTo(b.fechaActividad ?? DateTime.now()));
  }

  // Limpiar estado
  void limpiar() {
    _actividades = <Actividad>[];
    _asistenciaUsuario.clear();
  _apuntadoIdsPorActividad.clear();
  _apuntadosPorActividad.clear();
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
