import 'package:flutter/foundation.dart';
import 'package:xplorago/modelo/actividad.dart';
import 'package:xplorago/nucleo/servicios/actividad_servicio.dart';

class ActividadControl extends ChangeNotifier {
  final ActividadServicio _servicio = ActividadServicio();

  List<Actividad> _actividades = <Actividad>[];
  bool _cargando = false;
  String? _error;

  // Getters
  List<Actividad> get actividades => _actividades;
  bool get cargando => _cargando;
  String? get error => _error;

  // Método para cargar actividades de un grupo
  Future<void> cargarActividadesPorGrupo(String grupoId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      _actividades = await _servicio.obtenerPorGrupo(grupoId);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
    }
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
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
