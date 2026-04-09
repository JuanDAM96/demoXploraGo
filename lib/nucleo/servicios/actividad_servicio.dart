import 'package:xplorago/modelo/actividad.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';

class ActividadServicio {
  // Obtener actividades de un grupo
  Future<List<Actividad>> obtenerPorGrupo(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('actividades')
          .select()
          .eq('grupo_id', grupoId)
          .order('fecha_actividad', ascending: true);

      return (respuesta as List<dynamic>)
          .map((mapa) => Actividad.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar actividades: $e');
    }
  }

  // Obtener una actividad por ID
  Future<Actividad> obtenerPorId(String actividadId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('actividades')
          .select()
          .eq('id', actividadId)
          .single();

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al obtener actividad: $e');
    }
  }

  // Crear nueva actividad
  Future<Actividad> crear({
    required String grupoId,
    required String titulo,
    String? descripcion,
    String? lugar,
    DateTime? fechaActividad,
    double? costo,
    String? creadoPor,
  }) async {
    try {
      final mapa = <String, dynamic>{
        'grupo_id': grupoId,
        'titulo': titulo,
        'descripcion': descripcion,
        'lugar': lugar,
        'fecha_actividad': fechaActividad?.toIso8601String(),
        'costo': costo,
        'creado_por': creadoPor,
        'completada': false,
      };

      final respuesta = await SupabaseConexion.cliente
          .from('actividades')
          .insert(mapa)
          .select()
          .single();

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al crear actividad: $e');
    }
  }

  // Actualizar actividad
  Future<Actividad> actualizar(Actividad actividad) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('actividades')
          .update(actividad.toMap())
          .eq('id', actividad.id)
          .select()
          .single();

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al actualizar actividad: $e');
    }
  }

  // Eliminar actividad
  Future<void> eliminar(String actividadId) async {
    try {
      await SupabaseConexion.cliente
          .from('actividades')
          .delete()
          .eq('id', actividadId);
    } catch (e) {
      throw Exception('Error al eliminar actividad: $e');
    }
  }

  // Marcar como completada
  Future<Actividad> marcarCompletada(String actividadId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('actividades')
          .update({'completada': true})
          .eq('id', actividadId)
          .select()
          .single();

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al marcar como completada: $e');
    }
  }
}
