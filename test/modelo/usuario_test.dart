import 'package:flutter_test/flutter_test.dart';
import 'package:xplorago/modelo/usuario.dart';

void main() {
  group('Usuario', () {
    test('fromMap mapea campos principales y fallback', () {
      final Usuario usuario = Usuario.fromMap(<String, dynamic>{
        'id_usuario': 'u-1',
        'nombre': 'Juan',
        'apellidos': 'Pérez',
        'nombre_usuario': 'juanp',
        'email': 'juan@test.com',
        'telefono': '123',
        'codigo_postal': '28001',
        'fecha_nacimiento': '1990-01-01',
        'creado_el': '2026-04-01T10:00:00Z',
      });

      expect(usuario.id, 'u-1');
      expect(usuario.nombre, 'Juan');
      expect(usuario.nombreUsuario, 'juanp');
      expect(usuario.correo, 'juan@test.com');
      expect(usuario.codigoPostal, '28001');
      expect(usuario.creadoEn, isNotNull);
    });

    test('toMap y copyWith mantienen consistencia', () {
      final Usuario base = Usuario(
        id: 'u-2',
        nombre: 'Ana',
        correo: 'ana@test.com',
      );

      final Usuario actualizado = base.copyWith(nombre: 'Ana Maria');
      final Map<String, dynamic> mapa = actualizado.toMap();

      expect(actualizado.id, 'u-2');
      expect(actualizado.nombre, 'Ana Maria');
      expect(mapa['id'], 'u-2');
      expect(mapa['nombre'], 'Ana Maria');
      expect(mapa['correo'], 'ana@test.com');
    });
  });
}
