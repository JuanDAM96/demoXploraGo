import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';

class GastoServicio {
  // Obtener gastos de un grupo
  Future<List<Gasto>> obtenerPorGrupo(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('gastos')
          .select()
          .eq('grupo_id', grupoId)
          .order('fecha', ascending: false);

      return (respuesta as List<dynamic>)
          .map((mapa) => Gasto.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar gastos: $e');
    }
  }

  // Obtener un gasto por ID
  Future<Gasto> obtenerPorId(String gastoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('gastos')
          .select()
          .eq('id', gastoId)
          .single();

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
  }) async {
    try {
      final mapa = <String, dynamic>{
        'grupo_id': grupoId,
        'descripcion': descripcion,
        'monto': monto,
        'pagado_por': pagadoPor,
        'fecha': fecha?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'dividido_entre': divididoEntre ?? <String>[],
      };

      final respuesta = await SupabaseConexion.cliente
          .from('gastos')
          .insert(mapa)
          .select()
          .single();

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al crear gasto: $e');
    }
  }

  // Actualizar gasto
  Future<Gasto> actualizar(Gasto gasto) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('gastos')
          .update(gasto.toMap())
          .eq('id', gasto.id)
          .select()
          .single();

      return Gasto.fromMap(respuesta);
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> eliminar(String gastoId) async {
    try {
      await SupabaseConexion.cliente.from('gastos').delete().eq('id', gastoId);
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // Obtener gastos pagados por un usuario en un grupo
  Future<List<Gasto>> obtenerPagadosPor(String grupoId, String usuarioId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('gastos')
          .select()
          .eq('grupo_id', grupoId)
          .eq('pagado_por', usuarioId)
          .order('fecha', ascending: false);

      return (respuesta as List<dynamic>)
          .map((mapa) => Gasto.fromMap(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar gastos: $e');
    }
  }

  // Obtener total gastado en un grupo
  Future<double> obtenerTotal(String grupoId) async {
    try {
      final respuesta = await SupabaseConexion.cliente
          .from('gastos')
          .select('monto')
          .eq('grupo_id', grupoId);

      double total = 0;
      for (final mapa in respuesta as List<dynamic>) {
        total += (mapa['monto'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Error al calcular total: $e');
    }
  }
}
