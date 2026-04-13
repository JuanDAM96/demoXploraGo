import 'package:flutter_test/flutter_test.dart';
import 'package:xplorago/nucleo/temas/texto_util.dart';

void main() {
  group('obtenerIniciales', () {
    test('devuelve iniciales de nombre y apellido', () {
      expect(obtenerIniciales('Juan Perez'), 'JP');
    });

    test('maneja nombre único', () {
      expect(obtenerIniciales('juan'), 'J');
    });

    test('maneja espacios extra sin romper', () {
      expect(obtenerIniciales('  Juan   Perez  '), 'JP');
    });

    test('maneja texto vacío', () {
      expect(obtenerIniciales('   '), 'U');
    });
  });
}
