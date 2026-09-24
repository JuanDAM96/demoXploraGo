import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GastoServicio {
  dynamic get _tablaGastos => SupabaseConexion.cliente.from('gastos');

  static const List<String> _camposGrupo = <String>['id_grupo', 'grupo_id'];
  static const List<String> _camposActividad = <String>[
    'actividad_id',
    'id_actividad',
  ];
  static const List<String> _camposId = <String>['id_gasto', 'id'];
  static const List<String> _camposDescripcion = <String>[
    'descripcion',
    'concepto',
  ];
  static const List<String> _camposPagadoPor = <String>[
    'pagado_por',
    'pagador_id',
  ];
  static const List<String?> _camposFecha = <String?>[
    'fecha',
    'creado_en',
    null,
  ];
  static const List<String> _camposDivision = <String>[
    'dividido_entre',
    'participantes',
  ];

  List<Gasto> _mapearGastos(List<dynamic> respuesta) {
    return respuesta
        .map((mapa) => Gasto.fromMap(mapa as Map<String, dynamic>))
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

  List<Gasto> _ordenarPorFechaDesc(List<Gasto> gastos) {
    final List<Gasto> copia = List<Gasto>.from(gastos);
    copia.sort((Gasto a, Gasto b) {
      final DateTime da = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime db = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return copia;
  }

  bool _perteneceAlGrupo(Map<String, dynamic> mapa, String grupoId) {
    final String gid = (mapa['id_grupo'] ?? mapa['grupo_id'] ?? '').toString();
    return gid == grupoId;
  }

  bool _esPagadoPor(Map<String, dynamic> mapa, String usuarioId) {
    final String pid =
        (mapa['pagado_por'] ?? mapa['pagador_id'] ?? '').toString();
    return pid == usuarioId;
  }

  bool _perteneceActividad(Map<String, dynamic> mapa, String actividadId) {
    final String aid =
        (mapa['actividad_id'] ?? mapa['id_actividad'] ?? '').toString();
    return aid == actividadId;
  }

  Future<List<dynamic>> _obtenerTodosRaw() async {
    final dynamic r = await _tablaGastos.select();
    return r as List<dynamic>;
  }

  Future<List<dynamic>> _consultarPorGrupoConVariantes({
    required String grupoId,
    String? actividadId,
    String? pagadoPor,
    bool soloMonto = false,
  }) async {
    dynamic ultimoError;

    final List<String?> camposActividadConsulta = actividadId == null
        ? <String?>[null]
        : _camposActividad.cast<String?>();

    final List<String?> camposPagadorConsulta = pagadoPor == null
        ? <String?>[null]
        : _camposPagadoPor.cast<String?>();

    for (final String campoGrupo in _camposGrupo) {
      for (final String? campoActividad in camposActividadConsulta) {
        for (final String? campoPagador in camposPagadorConsulta) {
          for (final String? campoFecha in _camposFecha) {
            try {
              dynamic query = _tablaGastos.select(soloMonto ? 'monto' : '*').eq(
                campoGrupo,
                grupoId,
              );

              if (actividadId != null && campoActividad != null) {
                query = query.eq(campoActividad, actividadId);
              }

              if (pagadoPor != null && campoPagador != null) {
                query = query.eq(campoPagador, pagadoPor);
              }

              if (campoFecha != null && !soloMonto) {
                query = query.order(campoFecha, ascending: false);
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
    }

    final List<dynamic> todos = await _obtenerTodosRaw();
    final List<dynamic> filtrados = todos.where((dynamic item) {
      if (item is! Map<String, dynamic>) return false;
      if (!_perteneceAlGrupo(item, grupoId)) return false;
      if (actividadId != null && !_perteneceActividad(item, actividadId)) {
        return false;
      }
      if (pagadoPor != null && !_esPagadoPor(item, pagadoPor)) return false;
      return true;
    }).toList();

    if (filtrados.isNotEmpty) return filtrados;
    if (ultimoError != null) throw ultimoError;
    return filtrados;
  }

  Future<Map<String, dynamic>> _obtenerPorIdConVariantes(String gastoId) async {
    dynamic ultimoError;
    for (final String campoId in _camposId) {
      try {
        final dynamic r = await _tablaGastos.select().eq(campoId, gastoId).single();
        return r as Map<String, dynamic>;
      } catch (e) {
        if (!_esErrorEsquema(e)) rethrow;
        ultimoError = e;
      }
    }
    throw ultimoError ?? Exception('No se pudo obtener el gasto por ID.');
  }

  Future<Map<String, dynamic>> _actualizarConVariantes({
    required String gastoId,
    required List<Map<String, dynamic>> variantesPayload,
  }) async {
    dynamic ultimoError;
    for (final Map<String, dynamic> payload in variantesPayload) {
      for (final String campoId in _camposId) {
        try {
          final dynamic r = await _tablaGastos
              .update(payload)
              .eq(campoId, gastoId)
              .select()
              .single();
          return r as Map<String, dynamic>;
        } catch (e) {
          if (!_esErrorEsquema(e)) rethrow;
          ultimoError = e;
        }
      }
    }

    throw ultimoError ??
        Exception('No se pudo actualizar el gasto por incompatibilidad de esquema.');
  }

  Future<Map<String, dynamic>> _insertarConVariantes(
    List<Map<String, dynamic>> variantes,
  ) async {
    final Set<String> huellas = <String>{};
    final List<Map<String, dynamic>> variantesUnicas = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> payload in variantes) {
      final String huella = payload.entries
          .map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}')
          .join('|');
      if (huellas.add(huella)) {
        variantesUnicas.add(payload);
      }
    }

    dynamic ultimoError;
    for (final Map<String, dynamic> payload in variantesUnicas) {
      try {
        final dynamic r = await _tablaGastos.insert(payload).select().single();
        return r as Map<String, dynamic>;
      } catch (e) {
        if (!_esErrorEsquema(e)) rethrow;
        ultimoError = e;
      }
    }

    throw ultimoError ??
        Exception('No se pudo crear el gasto por incompatibilidad de esquema.');
  }

  // Obtener gastos de un grupo
  Future<List<Gasto>> obtenerPorGrupo(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
      );

      return _ordenarPorFechaDesc(_mapearGastos(respuesta));
    } catch (e) {
      throw Exception('Error al cargar gastos: $e');
    }
  }

  // Obtener un gasto por ID
  Future<Gasto> obtenerPorId(String gastoId) async {
    try {
      final Map<String, dynamic> respuesta = await _obtenerPorIdConVariantes(
        gastoId,
      );

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al obtener gasto: $e');
    }
  }

  // Crear nuevo gasto
  Future<Gasto> crear({
    required String grupoId,
    required String actividadId,
    required String descripcion,
    required double monto,
    required String pagadoPor,
    DateTime? fecha,
    List<String>? divididoEntre,
    Map<String, double>? reparto,
  }) async {
    try {
      final String fechaIso =
          fecha?.toIso8601String() ?? DateTime.now().toIso8601String();

      Map<String, dynamic> construirPayload({
        required String campoGrupo,
        required String campoDescripcion,
        required String campoPagadoPor,
        required String? campoFecha,
        required String? campoDivision,
        required bool incluirDivision,
        required bool incluirReparto,
      }) {
        final Map<String, dynamic> payload = <String, dynamic>{
          campoGrupo: grupoId,
          campoDescripcion: descripcion,
          'monto': monto,
          campoPagadoPor: pagadoPor,
        };
        payload['actividad_id'] = actividadId;
        if (campoFecha != null) {
          payload[campoFecha] = fechaIso;
        }
        if (incluirDivision && campoDivision != null) {
          payload[campoDivision] = divididoEntre ?? <String>[];
        }
        if (incluirReparto && reparto != null && reparto.isNotEmpty) {
          payload['reparto'] = reparto;
        }
        return payload;
      }

      final List<Map<String, dynamic>> variantes = <Map<String, dynamic>>[];
      for (final String campoActividad in _camposActividad) {
        for (final String campoGrupo in _camposGrupo) {
          for (final String campoDescripcion in _camposDescripcion) {
            for (final String campoPagador in _camposPagadoPor) {
              for (final String? campoFecha in _camposFecha) {
                for (final String? campoDivision in <String?>[
                  ..._camposDivision,
                  null,
                ]) {
                  final Map<String, dynamic> payloadConReparto = construirPayload(
                    campoGrupo: campoGrupo,
                    campoDescripcion: campoDescripcion,
                    campoPagadoPor: campoPagador,
                    campoFecha: campoFecha,
                    campoDivision: campoDivision,
                    incluirDivision: true,
                    incluirReparto: true,
                  );
                  payloadConReparto
                    ..remove('actividad_id')
                    ..[campoActividad] = actividadId;
                  variantes.add(payloadConReparto);

                  final Map<String, dynamic> payloadSinReparto = construirPayload(
                    campoGrupo: campoGrupo,
                    campoDescripcion: campoDescripcion,
                    campoPagadoPor: campoPagador,
                    campoFecha: campoFecha,
                    campoDivision: campoDivision,
                    incluirDivision: true,
                    incluirReparto: false,
                  );
                  payloadSinReparto
                    ..remove('actividad_id')
                    ..[campoActividad] = actividadId;
                  variantes.add(payloadSinReparto);

                  final Map<String, dynamic> payloadMinimo = construirPayload(
                    campoGrupo: campoGrupo,
                    campoDescripcion: campoDescripcion,
                    campoPagadoPor: campoPagador,
                    campoFecha: campoFecha,
                    campoDivision: campoDivision,
                    incluirDivision: false,
                    incluirReparto: false,
                  );
                  payloadMinimo
                    ..remove('actividad_id')
                    ..[campoActividad] = actividadId;
                  variantes.add(payloadMinimo);
                }
              }
            }
          }
        }
      }

      final Map<String, dynamic> respuesta = await _insertarConVariantes(
        variantes,
      );

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al crear gasto: $e');
    }
  }

  // Actualizar gasto
  Future<Gasto> actualizar(Gasto gasto) async {
    try {
      final List<Map<String, dynamic>> variantesPayload = <Map<String, dynamic>>[];

      for (final String campoGrupo in _camposGrupo) {
        for (final String campoDescripcion in _camposDescripcion) {
          for (final String campoPagador in _camposPagadoPor) {
            for (final String? campoFecha in _camposFecha) {
              for (final String? campoDivision in <String?>[
                ..._camposDivision,
                null,
              ]) {
                final Map<String, dynamic> payload = <String, dynamic>{
                  campoGrupo: gasto.grupoId,
                  'actividad_id': gasto.actividadId,
                  campoDescripcion: gasto.descripcion,
                  'monto': gasto.monto,
                  campoPagador: gasto.pagadoPor,
                  'reparto': gasto.reparto,
                };
                if (campoFecha != null) {
                  payload[campoFecha] = gasto.fecha?.toIso8601String();
                }
                if (campoDivision != null) {
                  payload[campoDivision] = gasto.divididoEntre;
                }
                variantesPayload.add(payload);
              }
            }
          }
        }
      }

      final Map<String, dynamic> respuesta = await _actualizarConVariantes(
        gastoId: gasto.id,
        variantesPayload: variantesPayload,
      );

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> eliminar(String gastoId) async {
    try {
      dynamic ultimoError;
      for (final String campoId in _camposId) {
        try {
          await _tablaGastos.delete().eq(campoId, gastoId);
          return;
        } catch (e) {
          if (!_esErrorEsquema(e)) rethrow;
          ultimoError = e;
        }
      }
      if (ultimoError != null) throw ultimoError;
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // Obtener gastos pagados por un usuario en un grupo
  Future<List<Gasto>> obtenerPagadosPor(String grupoId, String usuarioId) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
        pagadoPor: usuarioId,
      );

      return _ordenarPorFechaDesc(_mapearGastos(respuesta));
    } catch (e) {
      throw Exception('Error al cargar gastos: $e');
    }
  }

  Future<List<Gasto>> obtenerPorGrupoYActividad({
    required String grupoId,
    required String actividadId,
  }) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
        actividadId: actividadId,
      );

      return _ordenarPorFechaDesc(_mapearGastos(respuesta));
    } catch (e) {
      throw Exception('Error al cargar gastos por actividad: $e');
    }
  }

  // Obtener total gastado en un grupo
  Future<double> obtenerTotal(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
        soloMonto: true,
      );

      double total = 0;
      for (final dynamic mapa in respuesta) {
        if (mapa is! Map<String, dynamic>) continue;
        total += ((mapa['monto'] as num?) ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Error al calcular total: $e');
    }
  }

  Future<double> obtenerTotalPorActividad({
    required String grupoId,
    required String actividadId,
  }) async {
    try {
      final List<dynamic> respuesta = await _consultarPorGrupoConVariantes(
        grupoId: grupoId,
        actividadId: actividadId,
        soloMonto: true,
      );

      double total = 0;
      for (final dynamic mapa in respuesta) {
        if (mapa is! Map<String, dynamic>) continue;
        total += ((mapa['monto'] as num?) ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Error al calcular total por actividad: $e');
    }
  }
}
