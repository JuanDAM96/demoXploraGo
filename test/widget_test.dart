import 'package:flutter_test/flutter_test.dart';
import 'package:xplorago/modelo/grupo.dart';

void main() {
  test('Grupo.fromMap mapea esquema de Supabase', () {
    final Grupo grupo = Grupo.fromMap(<String, dynamic>{
      'id_grupo': 'abc-123',
      'nombre': 'Ruta Norte',
      'destino': 'Bilbao',
      'descripcion': 'Viaje en equipo',
      'creado_el': '2026-04-09T10:30:00Z',
      'miembros': <Map<String, dynamic>>[
        <String, dynamic>{'id_usuario': 'u1'},
        <String, dynamic>{'id_usuario': 'u2'},
      ],
    });

    expect(grupo.id, 'abc-123');
    expect(grupo.nombre, 'Ruta Norte');
    expect(grupo.destino, 'Bilbao');
    expect(grupo.miembrosCount, 2);
    expect(grupo.creadoEn, isNotNull);
  });

  test('Grupo.copyWith y toMap mantienen valores esperados', () {
    final Grupo base = Grupo(
      id: 'g-1',
      nombre: 'Aventura',
      destino: 'Madrid',
      descripcion: 'Plan de finde',
    );

    final Grupo actualizado = base.copyWith(nombre: 'Aventura Plus');
    final Map<String, dynamic> mapa = actualizado.toMap();

    expect(actualizado.id, 'g-1');
    expect(actualizado.nombre, 'Aventura Plus');
    expect(mapa['nombre'], 'Aventura Plus');
    expect(mapa['destino'], 'Madrid');
    expect(mapa['descripcion'], 'Plan de finde');
  });
}
