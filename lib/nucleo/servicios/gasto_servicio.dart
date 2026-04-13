import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GastoServicio {
  dynamic get _tablaGastos => SupabaseConexion.cliente.from('gastos');

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

  Future<Map<String, dynamic>> _insertarConVariantes(
    List<Map<String, dynamic>> variantes,
  ) async {
    dynamic ultimoError;
    for (final Map<String, dynamic> payload in variantes) {
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
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await _tablaGastos
              .select()
              .eq('id_grupo', grupoId)
              .order('fecha', ascending: false);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await _tablaGastos
              .select()
              .eq('grupo_id', grupoId)
              .order('fecha', ascending: false);
          return r as List<dynamic>;
        },
      );

      return _mapearGastos(respuesta);
    } catch (e) {
      throw Exception('Error al cargar gastos: $e');
    }
  }

  // Obtener un gasto por ID
  Future<Gasto> obtenerPorId(String gastoId) async {
    try {
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await _tablaGastos
                  .select()
                  .eq('id_gasto', gastoId)
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await _tablaGastos
                  .select()
                  .eq('id', gastoId)
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al obtener gasto: $e');
    }
  }

  // Crear nuevo gasto
  Future<Gasto> crear({
    required String grupoId,
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
        required bool incluirDivision,
        required bool incluirReparto,
        required bool incluirFecha,
      }) {
        final Map<String, dynamic> payload = <String, dynamic>{
          campoGrupo: grupoId,
          campoDescripcion: descripcion,
          'monto': monto,
          'pagado_por': pagadoPor,
        };
        if (incluirFecha) {
          payload['fecha'] = fechaIso;
        }
        if (incluirDivision) {
          payload['dividido_entre'] = divididoEntre ?? <String>[];
        }
        if (incluirReparto && reparto != null && reparto.isNotEmpty) {
          payload['reparto'] = reparto;
        }
        return payload;
      }

      final List<Map<String, dynamic>> variantes = <Map<String, dynamic>>[];
      for (final bool incluirFecha in <bool>[true, false]) {
        for (final String campoGrupo in <String>['id_grupo', 'grupo_id']) {
          for (
            final String campoDescripcion in <String>['descripcion', 'concepto']
          ) {
            variantes.add(
              construirPayload(
                campoGrupo: campoGrupo,
                campoDescripcion: campoDescripcion,
                incluirDivision: true,
                incluirReparto: true,
                incluirFecha: incluirFecha,
              ),
            );
          }
        }
      }

      for (final bool incluirFecha in <bool>[true, false]) {
        for (final String campoGrupo in <String>['id_grupo', 'grupo_id']) {
          for (
            final String campoDescripcion in <String>['descripcion', 'concepto']
          ) {
            variantes.add(
              construirPayload(
                campoGrupo: campoGrupo,
                campoDescripcion: campoDescripcion,
                incluirDivision: true,
                incluirReparto: false,
                incluirFecha: incluirFecha,
              ),
            );
            variantes.add(
              construirPayload(
                campoGrupo: campoGrupo,
                campoDescripcion: campoDescripcion,
                incluirDivision: false,
                incluirReparto: false,
                incluirFecha: incluirFecha,
              ),
            );
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
      final Map<String, dynamic> respuesta =
          await _conFallbackEsquema<Map<String, dynamic>>(
            primario: () async {
              final dynamic r = await _tablaGastos
                  .update(<String, dynamic>{
                    'id_grupo': gasto.grupoId,
                    'descripcion': gasto.descripcion,
                    'monto': gasto.monto,
                    'pagado_por': gasto.pagadoPor,
                    'fecha': gasto.fecha?.toIso8601String(),
                    'dividido_entre': gasto.divididoEntre,
                    'reparto': gasto.reparto,
                  })
                  .eq('id_gasto', gasto.id)
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
            fallback: () async {
              final dynamic r = await _tablaGastos
                  .update(gasto.toMap())
                  .eq('id', gasto.id)
                  .select()
                  .single();
              return r as Map<String, dynamic>;
            },
          );

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> eliminar(String gastoId) async {
    try {
      await _conFallbackEsquema<void>(
        primario: () async {
          await _tablaGastos.delete().eq('id_gasto', gastoId);
        },
        fallback: () async {
          await _tablaGastos.delete().eq('id', gastoId);
        },
      );
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // Obtener gastos pagados por un usuario en un grupo
  Future<List<Gasto>> obtenerPagadosPor(String grupoId, String usuarioId) async {
    try {
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await _tablaGastos
              .select()
              .eq('id_grupo', grupoId)
              .eq('pagado_por', usuarioId)
              .order('fecha', ascending: false);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await _tablaGastos
              .select()
              .eq('grupo_id', grupoId)
              .eq('pagado_por', usuarioId)
              .order('fecha', ascending: false);
          return r as List<dynamic>;
        },
      );

      return _mapearGastos(respuesta);
    } catch (e) {
      throw Exception('Error al cargar gastos: $e');
    }
  }

  // Obtener total gastado en un grupo
  Future<double> obtenerTotal(String grupoId) async {
    try {
      final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
        primario: () async {
          final dynamic r = await _tablaGastos.select('monto').eq('id_grupo', grupoId);
          return r as List<dynamic>;
        },
        fallback: () async {
          final dynamic r = await _tablaGastos.select('monto').eq('grupo_id', grupoId);
          return r as List<dynamic>;
        },
      );

      double total = 0;
      for (final mapa in respuesta) {
        total += (mapa['monto'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Error al calcular total: $e');
    }
  }
}
