import 'package:xplorago/modelo/mensaje.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MensajeServicio {
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

  // Obtener mensajes de un grupo
  Future<List<Mensaje>> obtenerPorGrupo(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('mensajes')
              .select()
              .eq('id_grupo', grupoId)
              .order('enviado_en', ascending: true);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('mensajes')
              .select()
              .eq('grupo_id', grupoId)
              .order('creado_en', ascending: true);
          return r as List<dynamic>;
        },
      );

    return respuesta
          .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar mensajes: $e');
    }
  }

  // Obtener un mensaje por ID
  Future<Mensaje> obtenerPorId(String mensajeId) async {
    try {
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('mensajes')
                  .select()
                  .eq('id_mensaje', mensajeId)
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('mensajes')
                  .select()
                  .eq('id', mensajeId)
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Mensaje.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al obtener mensaje: $e');
    }
  }

  // Crear nuevo mensaje
  Future<Mensaje> crear({
    required String grupoId,
    required String usuarioId,
    required String texto,
  }) async {
    try {
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('mensajes')
                  .insert(<String, dynamic>{
                    'id_grupo': grupoId,
                    'id_usuario': usuarioId,
                    'contenido': texto,
                    'enviado_en': DateTime.now().toIso8601String(),
                    'leido': false,
                  })
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await SupabaseConexion.cliente
                  .from('mensajes')
                  .insert(<String, dynamic>{
                    'grupo_id': grupoId,
                    'usuario_id': usuarioId,
                    'texto': texto,
                    'creado_en': DateTime.now().toIso8601String(),
                    'leido': false,
                  })
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Mensaje.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  // Marcar mensaje como leído
  Future<void> marcarComoLeido(String mensajeId) async {
    try {
      await _conFallbackEsquema<void>(
        primario: () async {
          await SupabaseConexion.cliente
              .from('mensajes')
              .update(<String, dynamic>{'leido': true})
              .eq('id_mensaje', mensajeId);
        },
        fallback: () async {
          await SupabaseConexion.cliente
              .from('mensajes')
              .update(<String, dynamic>{'leido': true})
              .eq('id', mensajeId);
        },
      );
    } catch (e) {
      throw Exception('Error al marcar como leído: $e');
    }
  }

  // Marcar todos como leídos en un grupo
  Future<void> marcarTodosComoLeidos(String grupoId, String usuarioId) async {
    try {
      await _conFallbackEsquema<void>(
        primario: () async {
          await SupabaseConexion.cliente
              .from('mensajes')
              .update(<String, dynamic>{'leido': true})
              .eq('id_grupo', grupoId)
              .neq('id_usuario', usuarioId);
        },
        fallback: () async {
          await SupabaseConexion.cliente
              .from('mensajes')
              .update(<String, dynamic>{'leido': true})
              .eq('grupo_id', grupoId)
              .neq('usuario_id', usuarioId);
        },
      );
    } catch (e) {
      throw Exception('Error al marcar como leídos: $e');
    }
  }

  // Eliminar mensaje
  Future<void> eliminar(String mensajeId) async {
    try {
      await _conFallbackEsquema<void>(
        primario: () async {
          await SupabaseConexion.cliente
              .from('mensajes')
              .delete()
              .eq('id_mensaje', mensajeId);
        },
        fallback: () async {
          await SupabaseConexion.cliente
              .from('mensajes')
              .delete()
              .eq('id', mensajeId);
        },
      );
    } catch (e) {
      throw Exception('Error al eliminar mensaje: $e');
    }
  }

  // Obtener mensajes no leídos de un grupo
  Future<List<Mensaje>> obtenerNoLeidos(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('mensajes')
              .select()
              .eq('id_grupo', grupoId)
              .eq('leido', false)
              .order('enviado_en', ascending: true);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('mensajes')
              .select()
              .eq('grupo_id', grupoId)
              .eq('leido', false)
              .order('creado_en', ascending: true);
          return r as List<dynamic>;
        },
      );

    return respuesta
          .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar mensajes no leídos: $e');
    }
  }

  // Obtener mensajes de un usuario en un grupo
  Future<List<Mensaje>> obtenerDelUsuario(String grupoId, String usuarioId) async {
    try {
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('mensajes')
              .select()
              .eq('id_grupo', grupoId)
              .eq('id_usuario', usuarioId)
              .order('enviado_en', ascending: true);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await SupabaseConexion.cliente
              .from('mensajes')
              .select()
              .eq('grupo_id', grupoId)
              .eq('usuario_id', usuarioId)
              .order('creado_en', ascending: true);
          return r as List<dynamic>;
        },
      );

    return respuesta
          .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar mensajes: $e');
    }
  }
}
