import 'package:flutter_test/flutter_test.dart';
import 'package:xplorago/modelo/actividad.dart';

void main() {
  group('Actividad', () {
    test('fromMap mapea campos y fallback de ids', () {
      final Actividad actividad = Actividad.fromMap(<String, dynamic>{
        'id_actividad': 'a-1',
        'id_grupo': 'g-1',
        'titulo': 'Museo',
        'descripcion': 'Visita guiada',
        'lugar': 'Centro',
        'fecha_actividad': '2026-05-02T09:00:00Z',
        'costo': 18.5,
        'id_usuario': 'u-1',
        'completada': false,
      });

      expect(actividad.id, 'a-1');
      expect(actividad.grupoId, 'g-1');
      expect(actividad.titulo, 'Museo');
      expect(actividad.costo, 18.5);
      expect(actividad.creadoPor, 'u-1');
      expect(actividad.completada, isFalse);
      expect(actividad.fechaActividad, isNotNull);
    });

    test('copyWith y toMap reflejan cambios', () {
      final Actividad base = Actividad(
        id: 'a-2',
        grupoId: 'g-2',
        titulo: 'Cena',
        completada: false,
      );

      final Actividad actualizada = base.copyWith(completada: true, costo: 30);
      final Map<String, dynamic> mapa = actualizada.toMap();

      expect(actualizada.completada, isTrue);
      expect(actualizada.costo, 30);
      expect(mapa['grupo_id'], 'g-2');
      expect(mapa['completada'], isTrue);
      expect(mapa['costo'], 30);
    });
  });
}
