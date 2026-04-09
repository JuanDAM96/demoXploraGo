import 'package:xplorago/modelo/grupo.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';

class GrupoServicio {
  // Obtener todos los grupos de un usuario (como miembro o creador)
  Future<List<Grupo>> obtenerPorUsuario(String usuarioId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('grupos')
          .select()
          .or('creador_id.eq.$usuarioId,miembros.cs.{"$usuarioId"}');

      return (respuesta as List<dynamic>)
          .map((mapa) => Grupo.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar grupos: $e');
    }
  }

  // Obtener un grupo por ID
  Future<Grupo> obtenerPorId(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('grupos')
          .select()
          .eq('id', grupoId)
          .single();

      return Grupo.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al obtener grupo: $e');
    }
  }

  // Crear nuevo grupo
  Future<Grupo> crear({
    required String nombre,
    String? destino,
    String? descripcion,
    required String creadorId,
  }) async {
    try {
      final mapa = <String, dynamic>{
        'nombre': nombre,
        'destino': destino,
        'descripcion': descripcion,
        'creador_id': creadorId,
        'miembros_count': 1,
      };

      final respuesta = await SupabaseConexion.cliente
          .from('grupos')
          .insert(mapa)
          .select()
          .single();

      return Grupo.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al crear grupo: $e');
    }
  }

  // Actualizar grupo
  Future<Grupo> actualizar(Grupo grupo) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('grupos')
          .update(grupo.toMap())
          .eq('id', grupo.id)
          .select()
          .single();

      return Grupo.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al actualizar grupo: $e');
    }
  }

  // Eliminar grupo
  Future<void> eliminar(String grupoId) async {
    try {
      await SupabaseConexion.cliente.from('grupos').delete().eq('id', grupoId);
    } catch (e) {
      throw Exception('Error al eliminar grupo: $e');
    }
  }

  // Agregar miembro a un grupo
  Future<void> agregarMiembro(String grupoId, String usuarioId) async {
    try {
      await SupabaseConexion.cliente.from('miembros_grupo').insert({
        'grupo_id': grupoId,
        'usuario_id': usuarioId,
      });
    } catch (e) {
      throw Exception('Error al agregar miembro: $e');
    }
  }

  // Eliminar miembro del grupo
  Future<void> eliminarMiembro(String grupoId, String usuarioId) async {
    try {
      await SupabaseConexion.cliente
          .from('miembros_grupo')
          .delete()
          .eq('grupo_id', grupoId)
          .eq('usuario_id', usuarioId);
    } catch (e) {
      throw Exception('Error al eliminar miembro: $e');
    }
  }

  // Obtener miembros de un grupo
  Future<List<String>> obtenerMiembroIds(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('miembros_grupo')
          .select('usuario_id')
          .eq('grupo_id', grupoId);

      return (respuesta as List<dynamic>)
          .map((m) => m['usuario_id'].toString())
          .toList();
    } catch (e) {
      throw Exception('Error al obtener miembros: $e');
    }
  }
}
