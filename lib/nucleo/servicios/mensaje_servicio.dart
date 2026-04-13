import 'package:xplorago/modelo/mensaje.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MensajeServicio {
  dynamic get _tablaMensajes => SupabaseConexion.cliente.from('mensajes');

  static const List<String> _camposGrupo = <String>['id_grupo', 'grupo_id'];
  static const List<String> _camposUsuario = <String>[
    'id_usuario',
    'usuario_id',
  ];
  static const List<String> _camposTexto = <String>['contenido', 'texto', 'mensaje'];
  static const List<String?> _camposFecha = <String?>[
    'enviado_en',
    'creado_en',
    'fecha',
    null,
  ];

  static const Map<String, dynamic> _leidoTrue = <String, dynamic>{
    'leido': true,
  };

  List<Mensaje> _mapearMensajes(List<dynamic> respuesta) {
    return respuesta
        .map((mapa) => Mensaje.fromMap(mapa as Map<String, dynamic>))
        .toList();
  }

  bool _esErrorEsquema(dynamic e) {
    if (e is! PostgrestException) return false;
    final String? code = e.code;
    final String msg = e.message.toLowerCase();
  return code == '42703' ||
    code == 'PGRST204' ||
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

  List<Mensaje> _ordenarPorFechaAsc(List<Mensaje> mensajes) {
    final List<Mensaje> copia = List<Mensaje>.from(mensajes);
    copia.sort((Mensaje a, Mensaje b) {
      final DateTime da = a.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime db = b.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    return copia;
  }

  bool _perteneceAlGrupo(Map<String, dynamic> mapa, String grupoId) {
    final String gid = (mapa['id_grupo'] ?? mapa['grupo_id'] ?? '').toString();
    return gid == grupoId;
  }

  bool _esDeUsuario(Map<String, dynamic> mapa, String usuarioId) {
    final String uid =
        (mapa['id_usuario'] ?? mapa['usuario_id'] ?? '').toString();
    return uid == usuarioId;
  }

  bool _estaNoLeido(Map<String, dynamic> mapa) {
    final dynamic leido = mapa['leido'];
    return leido != true;
  }

  Future<List<dynamic>> _obtenerTodosRaw() async {
    final dynamic r = await _tablaMensajes.select();
    return r as List<dynamic>;
  }

  Future<List<dynamic>> _consultarPorGrupoConVariantes({
    required String grupoId,
    bool? soloNoLeidos,
    String? usuarioId,
  }) async {
    dynamic ultimoError;
    final List<String?> camposUsuarioConsulta = usuarioId == null
        ? <String?>[null]
        : _camposUsuario.cast<String?>();

    for (final String campoGrupo in _camposGrupo) {
      for (final String? campoUsuario in camposUsuarioConsulta) {
        for (final String? campoFecha in _camposFecha) {
          try {
            dynamic query = _tablaMensajes.select().eq(campoGrupo, grupoId);
            if (soloNoLeidos == true) {
              query = query.eq('leido', false);
            }

            if (usuarioId != null && campoUsuario != null) {
              query = query.eq(campoUsuario, usuarioId);
            }

            if (campoFecha != null) {
              query = query.order(campoFecha, ascending: true);
            }

            final dynamic r = await query;
            return r as List<dynamic>;
          } catch (e) {
            if (!_esErrorEsquema(e)) rethrow;
            ultimoError = e;
          }
        }
      }
    }

    final List<dynamic> todos = await _obtenerTodosRaw();
    final List<dynamic> filtrados = todos.where((dynamic item) {
      if (item is! Map<String, dynamic>) return false;
      if (!_perteneceAlGrupo(item, grupoId)) return false;
      if (usuarioId != null && !_esDeUsuario(item, usuarioId)) return false;
      if (soloNoLeidos == true && !_estaNoLeido(item)) return false;
      return true;
    }).toList();

    if (filtrados.isNotEmpty) return filtrados;
    if (ultimoError != null) throw ultimoError;
    return filtrados;
  }

  Future<Map<String, dynamic>> _insertarConVariantes(
    List<Map<String, dynamic>> variantes,
  ) async {
    dynamic ultimoError;
    for (final Map<String, dynamic> payload in variantes) {
      try {
        final dynamic r = await _tablaMensajes.insert(payload).select().single();
        return r as Map<String, dynamic>;
      } catch (e) {
        if (!_esErrorEsquema(e)) rethrow;
        ultimoError = e;
      }
    }

    throw ultimoError ??
        Exception('No se pudo crear el mensaje por incompatibilidad de esquema.');
  }

  // Obtener mensajes de un grupo
  Future<List<Mensaje>> obtenerPorGrupo(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
      );

      return _ordenarPorFechaAsc(_mapearMensajes(respuesta));
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
              final dynamic r = await _tablaMensajes
                  .select()
                  .eq('id_mensaje', mensajeId)
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await _tablaMensajes
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
      final String fechaIso = DateTime.now().toIso8601String();

      Map<String, dynamic> construirPayload({
        required String campoGrupo,
        required String campoUsuario,
        required String campoTexto,
        required String? campoFecha,
        required bool incluirLeido,
      }) {
        final Map<String, dynamic> payload = <String, dynamic>{
          campoGrupo: grupoId,
          campoUsuario: usuarioId,
          campoTexto: texto,
        };
        if (incluirLeido) {
          payload['leido'] = false;
        }
        if (campoFecha != null) {
          payload[campoFecha] = fechaIso;
        }
        return payload;
      }

      final List<Map<String, dynamic>> variantes = <Map<String, dynamic>>[];
      for (final String campoGrupo in _camposGrupo) {
        for (final String campoUsuario in _camposUsuario) {
          for (final String campoTexto in _camposTexto) {
            for (final String? campoFecha in _camposFecha) {
              variantes.add(
                construirPayload(
                  campoGrupo: campoGrupo,
                  campoUsuario: campoUsuario,
                  campoTexto: campoTexto,
                  campoFecha: campoFecha,
                  incluirLeido: true,
                ),
              );
              variantes.add(
                construirPayload(
                  campoGrupo: campoGrupo,
                  campoUsuario: campoUsuario,
                  campoTexto: campoTexto,
                  campoFecha: campoFecha,
                  incluirLeido: false,
                ),
              );
            }
          }
        }
      }

      final Map<String, dynamic> respuesta = await _insertarConVariantes(
        variantes,
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
          await _tablaMensajes.update(_leidoTrue).eq('id_mensaje', mensajeId);
        },
        fallback: () async {
          await _tablaMensajes.update(_leidoTrue).eq('id', mensajeId);
        },
      );
    } catch (e) {
      throw Exception('Error al marcar como leído: $e');
    }
  }

  // Marcar todos como leídos en un grupo
  Future<void> marcarTodosComoLeidos(String grupoId, String usuarioId) async {
    try {
      dynamic ultimoError;
      for (final String campoGrupo in _camposGrupo) {
        for (final String campoUsuario in _camposUsuario) {
          try {
            await _tablaMensajes
                .update(_leidoTrue)
                .eq(campoGrupo, grupoId)
                .neq(campoUsuario, usuarioId);
            return;
          } catch (e) {
            if (!_esErrorEsquema(e)) rethrow;
            ultimoError = e;
          }
        }
      }
      if (ultimoError != null) throw ultimoError;
    } catch (e) {
      throw Exception('Error al marcar como leídos: $e');
    }
  }

  // Eliminar mensaje
  Future<void> eliminar(String mensajeId) async {
    try {
      await _conFallbackEsquema<void>(
        primario: () async {
          await _tablaMensajes.delete().eq('id_mensaje', mensajeId);
        },
        fallback: () async {
          await _tablaMensajes.delete().eq('id', mensajeId);
        },
      );
    } catch (e) {
      throw Exception('Error al eliminar mensaje: $e');
    }
  }

  // Obtener mensajes no leídos de un grupo
  Future<List<Mensaje>> obtenerNoLeidos(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
        soloNoLeidos: true,
      );

      return _ordenarPorFechaAsc(_mapearMensajes(respuesta));
    } catch (e) {
      throw Exception('Error al cargar mensajes no leídos: $e');
    }
  }

  // Obtener mensajes de un usuario en un grupo
  Future<List<Mensaje>> obtenerDelUsuario(String grupoId, String usuarioId) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
        usuarioId: usuarioId,
      );

      return _ordenarPorFechaAsc(_mapearMensajes(respuesta));
    } catch (e) {
      throw Exception('Error al cargar mensajes: $e');
    }
  }
}
