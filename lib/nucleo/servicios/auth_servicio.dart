import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';

class AuthServicio {
  final SupabaseClient _client = SupabaseConexion.cliente;

  Future<User> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final AuthResponse respuesta = await _client.auth.signInWithPassword(
      email: correo,
      password: contrasena,
    );

    final User? usuario = respuesta.user ?? respuesta.session?.user;
    if (usuario == null) {
      throw Exception('No se pudo iniciar sesion. Verifica tus credenciales.');
    }

    return usuario;
  }

  Future<User> registrar({
    required String correo,
    required String contrasena,
    String? nombreUsuario,
  }) async {
    final AuthResponse respuesta = await _client.auth.signUp(
      email: correo,
      password: contrasena,
      data: <String, dynamic>{
        if (nombreUsuario != null && nombreUsuario.trim().isNotEmpty)
          'nombre_usuario': nombreUsuario.trim(),
      },
    );

    final User? usuario = respuesta.user ?? respuesta.session?.user;
    if (usuario == null) {
      throw Exception('No se pudo crear la cuenta. Intentalo de nuevo.');
    }

    return usuario;
  }

  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  Future<void> recuperarContrasena({required String correo}) async {
    await _client.auth.resetPasswordForEmail(correo);
  }

  Future<void> cambiarContrasena({required String nuevaContrasena}) async {
    await _client.auth.updateUser(UserAttributes(password: nuevaContrasena));
  }
}
