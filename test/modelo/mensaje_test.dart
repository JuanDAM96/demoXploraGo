import 'package:flutter_test/flutter_test.dart';
import 'package:xplorago/modelo/mensaje.dart';

void main() {
  group('Mensaje', () {
    test('fromMap soporta esquema principal', () {
      final Mensaje mensaje = Mensaje.fromMap(<String, dynamic>{
        'id_mensaje': 'm-1',
        'id_grupo': 'g-1',
        'id_usuario': 'u-1',
        'contenido': 'Hola equipo',
        'enviado_en': '2026-04-10T15:20:00Z',
        'leido': true,
      });

      expect(mensaje.id, 'm-1');
      expect(mensaje.grupoId, 'g-1');
      expect(mensaje.usuarioId, 'u-1');
      expect(mensaje.texto, 'Hola equipo');
      expect(mensaje.leido, isTrue);
      expect(mensaje.creadoEn, isNotNull);
    });

    test('toMap y copyWith con esquema fallback', () {
      final Mensaje mensaje = Mensaje.fromMap(<String, dynamic>{
        'id': 'm-legacy',
        'grupo_id': 'g-legacy',
        'usuario_id': 'u-legacy',
        'texto': 'Mensaje legacy',
      }).copyWith(leido: true);

      final Map<String, dynamic> mapa = mensaje.toMap();

      expect(mensaje.id, 'm-legacy');
      expect(mensaje.texto, 'Mensaje legacy');
      expect(mapa['grupo_id'], 'g-legacy');
      expect(mapa['usuario_id'], 'u-legacy');
      expect(mapa['leido'], isTrue);
    });
  });
}
