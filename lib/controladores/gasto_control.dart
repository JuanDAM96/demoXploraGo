import 'package:flutter/foundation.dart';
import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/nucleo/servicios/gasto_servicio.dart';

class GastoControl extends ChangeNotifier {
  final GastoServicio _servicio = GastoServicio();

  List<Gasto> _gastos = <Gasto>[];
  bool _cargando = false;
  String? _error;

  // Getters
  List<Gasto> get gastos => _gastos;
  bool get cargando => _cargando;
  String? get error => _error;

  // Cargar gastos de un grupo
  Future<void> cargarGastosPorGrupo(String grupoId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      _gastos = await _servicio.obtenerPorGrupo(grupoId);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _cargando = false;
      notifyListeners();
    }
  }

  // Crear nuevo gasto
  Future<void> crearGasto({
    required String grupoId,
    required String descripcion,
    required double monto,
    required String pagadoPor,
    DateTime? fecha,
    List<String>? divididoEntre,
  }) async {
    try {
      _error = null;
      final Gasto gasto = await _servicio.crear(
        grupoId: grupoId,
        descripcion: descripcion,
        monto: monto,
        pagadoPor: pagadoPor,
        fecha: fecha,
        divididoEntre: divididoEntre,
      );

      _gastos.add(gasto);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Actualizar gasto
  Future<void> actualizar(Gasto gasto) async {
    try {
      _error = null;
      final Gasto actualizado = await _servicio.actualizar(gasto);

      final int indice = _gastos.indexWhere((g) => g.id == actualizado.id);
      if (indice != -1) {
        _gastos[indice] = actualizado;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar gasto
  Future<void> eliminar(String gastoId) async {
    try {
      _error = null;
      await _servicio.eliminar(gastoId);

      _gastos.removeWhere((g) => g.id == gastoId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Obtener total de gastos
  double obtenerTotal() {
    return _gastos.fold(0, (suma, gasto) => suma + gasto.monto);
  }

  // Obtener gastos pagados por un usuario
  List<Gasto> obtenerPagadosPor(String usuarioId) {
    return _gastos.where((g) => g.pagadoPor == usuarioId).toList();
  }

  // Calcular quién le debe a quién
  Map<String, double> calcularDeudas(List<String> miembros) {
    final Map<String, double> deudas = {};

    for (final miembro in miembros) {
      deudas[miembro] = 0;
    }

    for (final gasto in _gastos) {
      if (gasto.divididoEntre.isNotEmpty) {
        final montoPorPersona = gasto.monto / gasto.divididoEntre.length;

        for (final usuarioId in gasto.divididoEntre) {
          if (usuarioId != gasto.pagadoPor) {
            deudas[usuarioId] = (deudas[usuarioId] ?? 0) + montoPorPersona;
          }
        }
      }
    }

    return deudas;
  }

  // Limpiar estado
  void limpiar() {
    _gastos = <Gasto>[];
    _error = null;
    _cargando = false;
    notifyListeners();
  }
}
