import 'package:xplorago/modelo/grupo.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GrupoServicio {
  static const Uuid _uuid = Uuid();

  Future<void> _asegurarSesionValida() async {
    final auth = SupabaseConexion.cliente.auth;
    final Session? session = auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      throw Exception('Tu sesión no es válida. Inicia sesión de nuevo.');
    }

    final int? expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final DateTime expiraEn = DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
      );
      if (!expiraEn.isAfter(DateTime.now())) {
        throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
      }
    }

    if (auth.currentUser == null) {
      throw Exception('No se pudo validar el usuario autenticado.');
    }
  }

  // Obtener todos los grupos de un usuario (si es miembro)
  Future<List<Grupo>> obtenerPorUsuario(String usuarioId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('grupos')
          .select(
            'id_grupo,nombre,destino,descripcion,fecha_inicio,fecha_fin,imagen_url,codigo_invitacion,creado_el,miembros!inner(id_usuario)',
          )
          .eq('miembros.id_usuario', usuarioId)
          .order('creado_el', ascending: false);

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
          .eq('id_grupo', grupoId)
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
    await _asegurarSesionValida();

    final String nuevoGrupoId = _uuid.v4();
    final mapa = <String, dynamic>{
      'id_grupo': nuevoGrupoId,
      'nombre': nombre,
      'destino': destino,
      'descripcion': descripcion,
    };

    try {
      await SupabaseConexion.cliente.from('grupos').insert(mapa);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception(
          'Permisos insuficientes al insertar en grupos (RLS 42501). Revisa la policy de INSERT en public.grupos: grupos_insert_authenticated.',
        );
      }
      throw Exception('Error al crear grupo (insert grupos): $e');
    }

    try {
      await SupabaseConexion.cliente.from('miembros').upsert(
        <String, dynamic>{
          'id_grupo': nuevoGrupoId,
          'id_usuario': creadorId,
          'rol': 'admin',
        },
        onConflict: 'id_usuario,id_grupo',
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception(
          'Grupo creado, pero sin permisos para insertarte como miembro admin (RLS 42501 en public.miembros). Revisa policy miembros_insert_self_or_admin.',
        );
      }
      throw Exception('Error al crear grupo (insert miembros): $e');
    }

    // Evitamos SELECT inmediato para no depender de policy SELECT justo tras el alta.
    return Grupo(
      id: nuevoGrupoId,
      nombre: nombre,
      destino: destino,
      descripcion: descripcion,
      miembrosCount: 1,
      creadoEn: DateTime.now(),
    );
  }

  // Actualizar grupo
  Future<Grupo> actualizar(Grupo grupo) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('grupos')
          .update(grupo.toMap())
          .eq('id_grupo', grupo.id)
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
      await SupabaseConexion.cliente
          .from('grupos')
          .delete()
          .eq('id_grupo', grupoId);
    } catch (e) {
      throw Exception('Error al eliminar grupo: $e');
    }
  }

  // Agregar miembro a un grupo
  Future<void> agregarMiembro(String grupoId, String usuarioId) async {
    try {
      await SupabaseConexion.cliente.from('miembros').insert({
        'id_grupo': grupoId,
        'id_usuario': usuarioId,
        'rol': 'miembro',
      });
    } catch (e) {
      throw Exception('Error al agregar miembro: $e');
    }
  }

  // Eliminar miembro del grupo
  Future<void> eliminarMiembro(String grupoId, String usuarioId) async {
    try {
      await SupabaseConexion.cliente
          .from('miembros')
          .delete()
          .eq('id_grupo', grupoId)
          .eq('id_usuario', usuarioId);
    } catch (e) {
      throw Exception('Error al eliminar miembro: $e');
    }
  }

  // Obtener miembros de un grupo
  Future<List<String>> obtenerMiembroIds(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('miembros')
          .select('id_usuario')
          .eq('id_grupo', grupoId);

      return (respuesta as List<dynamic>)
          .map((m) => m['id_usuario'].toString())
          .toList();
    } catch (e) {
      throw Exception('Error al obtener miembros: $e');
    }
  }

  // Obtener rol de un usuario dentro de un grupo
  Future<String?> obtenerRolMiembro(String grupoId, String usuarioId) async {
    try {
      final dynamic respuesta = await SupabaseConexion.cliente
          .from('miembros')
          .select('rol')
          .eq('id_grupo', grupoId)
          .eq('id_usuario', usuarioId)
          .maybeSingle();

      if (respuesta == null) return null;
      return (respuesta as Map<String, dynamic>)['rol']?.toString();
    } catch (e) {
      throw Exception('Error al obtener rol del miembro: $e');
    }
  }
}
