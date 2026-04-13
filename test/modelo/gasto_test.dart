import 'package:flutter_test/flutter_test.dart';
import 'package:xplorago/modelo/gasto.dart';

void main() {
  group('Gasto.fromMap', () {
    test('mapea esquema principal con reparto y dividido_entre', () {
      final Gasto gasto = Gasto.fromMap(<String, dynamic>{
        'id_gasto': 'g-1',
        'id_grupo': 'grupo-1',
        'descripcion': 'Cena',
        'monto': 120.5,
        'pagado_por': 'u1',
        'fecha': '2026-04-10T20:30:00Z',
        'dividido_entre': <String>['u1', 'u2'],
        'reparto': <String, dynamic>{'u1': 60, 'u2': 60.5},
      });

      expect(gasto.id, 'g-1');
      expect(gasto.grupoId, 'grupo-1');
      expect(gasto.descripcion, 'Cena');
      expect(gasto.monto, 120.5);
      expect(gasto.pagadoPor, 'u1');
      expect(gasto.divididoEntre, <String>['u1', 'u2']);
      expect(gasto.reparto['u1'], 60);
      expect(gasto.reparto['u2'], 60.5);
      expect(gasto.fecha, isNotNull);
    });

    test('mapea esquema fallback legacy', () {
      final Gasto gasto = Gasto.fromMap(<String, dynamic>{
        'id': 'legacy-1',
        'grupo_id': 'grupo-legacy',
        'concepto': 'Taxi',
        'monto': 25,
        'pagado_por': 'u9',
        'creado_en': '2026-04-11T08:00:00Z',
      });

      expect(gasto.id, 'legacy-1');
      expect(gasto.grupoId, 'grupo-legacy');
      expect(gasto.descripcion, 'Taxi');
      expect(gasto.monto, 25);
      expect(gasto.pagadoPor, 'u9');
      expect(gasto.reparto, isEmpty);
      expect(gasto.divididoEntre, isEmpty);
      expect(gasto.fecha, isNotNull);
    });
  });
}
