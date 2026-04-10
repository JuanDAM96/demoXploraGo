import 'package:xplorago/modelo/actividad.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActividadServicio {
  bool _esErrorEsquema(dynamic e) {
    if (e is! PostgrestException) return false;
  final String? code = e.code;
    final String msg = e.message.toLowerCase();
    return code == '42703' ||
        code == '42P01' ||
        msg.contains('column') ||
        msg.contains('relation');
  }

  Future<T> _conFallbackEsquema<T>({
    required Future<T> Function() primario,
    required Future<T> Function() fallback,
  }) async {
    try {
      return await primario();
    } catch (e) {
      if (!_esErrorEsquema(e)) rethrow;
      return fallback();
    }
  }

  // Obtener actividades de un grupo
  Future<List<Actividad>> obtenerPorGrupo(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('actividades')
              .select()
              .eq('id_grupo', grupoId)
              .order('fecha_actividad', ascending: true);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('actividades')
              .select()
              .eq('grupo_id', grupoId)
              .order('fecha_actividad', ascending: true);
          return r as List<dynamic>;
        },
      );

    return respuesta
          .map((mapa) => Actividad.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar actividades: $e');
    }
  }

  // Obtener una actividad por ID
  Future<Actividad> obtenerPorId(String actividadId) async {
    try {
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .select()
                  .eq('id_actividad', actividadId)
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .select()
                  .eq('id', actividadId)
                  .single();
              return r as Map<String, dynamic>;
            },
          );

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
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .insert(<String, dynamic>{
                    'id_grupo': grupoId,
                    'titulo': titulo,
                    'descripcion': descripcion,
                    'lugar': lugar,
                    'fecha_actividad': fechaActividad?.toIso8601String(),
                    'costo': costo,
                    'creado_por': creadoPor,
                    'completada': false,
                  })
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .insert(<String, dynamic>{
                    'grupo_id': grupoId,
                    'titulo': titulo,
                    'descripcion': descripcion,
                    'lugar': lugar,
                    'fecha_actividad': fechaActividad?.toIso8601String(),
                    'costo': costo,
                    'creado_por': creadoPor,
                    'completada': false,
                  })
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al crear actividad: $e');
    }
  }

  // Actualizar actividad
  Future<Actividad> actualizar(Actividad actividad) async {
    try {
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .update(<String, dynamic>{
                    'id_grupo': actividad.grupoId,
                    'titulo': actividad.titulo,
                    'descripcion': actividad.descripcion,
                    'lugar': actividad.lugar,
                    'fecha_actividad': actividad.fechaActividad
                        ?.toIso8601String(),
                    'costo': actividad.costo,
                    'creado_por': actividad.creadoPor,
                    'completada': actividad.completada,
                  })
                  .eq('id_actividad', actividad.id)
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .update(actividad.toMap())
                  .eq('id', actividad.id)
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al actualizar actividad: $e');
    }
  }

  // Eliminar actividad
  Future<void> eliminar(String actividadId) async {
    try {
      await _conFallbackEsquema<void>(
        primario: () async {
          await SupabaseConexion.cliente
              .from('actividades')
              .delete()
              .eq('id_actividad', actividadId);
        },
        fallback: () async {
          await SupabaseConexion.cliente
              .from('actividades')
              .delete()
              .eq('id', actividadId);
        },
      );
    } catch (e) {
      throw Exception('Error al eliminar actividad: $e');
    }
  }

  // Marcar como completada
  Future<Actividad> marcarCompletada(String actividadId) async {
    try {
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .update(<String, dynamic>{'completada': true})
                  .eq('id_actividad', actividadId)
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('actividades')
                  .update(<String, dynamic>{'completada': true})
                  .eq('id', actividadId)
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Actividad.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al marcar como completada: $e');
    }
  }
}
