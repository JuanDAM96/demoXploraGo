import 'package:xplorago/modelo/mensaje.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';

class MensajeServicio {
  // Obtener mensajes de un grupo
  Future<List<Mensaje>> obtenerPorGrupo(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('mensajes')
          .select()
          .eq('grupo_id', grupoId)
          .order('creado_en', ascending: true);

      return (respuesta as List<dynamic>)
          .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar mensajes: $e');
    }
  }

  // Obtener un mensaje por ID
  Future<Mensaje> obtenerPorId(String mensajeId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('mensajes')
          .select()
          .eq('id', mensajeId)
          .single();

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
      final mapa = <String, dynamic>{
        'grupo_id': grupoId,
        'usuario_id': usuarioId,
        'texto': texto,
        'creado_en': DateTime.now().toIso8601String(),
        'leido': false,
      };

      final respuesta = await SupabaseConexion.cliente
          .from('mensajes')
          .insert(mapa)
          .select()
          .single();

      return Mensaje.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  // Marcar mensaje como leído
  Future<void> marcarComoLeido(String mensajeId) async {
    try {
      await SupabaseConexion.cliente
          .from('mensajes')
          .update({'leido': true})
          .eq('id', mensajeId);
    } catch (e) {
      throw Exception('Error al marcar como leído: $e');
    }
  }

  // Marcar todos como leídos en un grupo
  Future<void> marcarTodosComoLeidos(String grupoId, String usuarioId) async {
    try {
      await SupabaseConexion.cliente
          .from('mensajes')
          .update({'leido': true})
          .eq('grupo_id', grupoId)
          .neq('usuario_id', usuarioId);
    } catch (e) {
      throw Exception('Error al marcar como leídos: $e');
    }
  }

  // Eliminar mensaje
  Future<void> eliminar(String mensajeId) async {
    try {
      await SupabaseConexion.cliente
          .from('mensajes')
          .delete()
          .eq('id', mensajeId);
    } catch (e) {
      throw Exception('Error al eliminar mensaje: $e');
    }
  }

  // Obtener mensajes no leídos de un grupo
  Future<List<Mensaje>> obtenerNoLeidos(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('mensajes')
          .select()
          .eq('grupo_id', grupoId)
          .eq('leido', false)
          .order('creado_en', ascending: true);

      return (respuesta as List<dynamic>)
          .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar mensajes no leídos: $e');
    }
  }

  // Obtener mensajes de un usuario en un grupo
  Future<List<Mensaje>> obtenerDelUsuario(String grupoId, String usuarioId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('mensajes')
          .select()
          .eq('grupo_id', grupoId)
          .eq('usuario_id', usuarioId)
          .order('creado_en', ascending: true);

      return (respuesta as List<dynamic>)
          .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar mensajes: $e');
    }
  }
}
