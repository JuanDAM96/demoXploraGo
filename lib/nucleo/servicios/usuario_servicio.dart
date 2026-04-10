import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioServicio {
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

	// Obtener usuario por ID
	Future<Usuario> obtenerPorId(String usuarioId) async {
		try {
			final Map<String, dynamic> respuesta =
					await _conFallbackEsquema<Map<String, dynamic>>(
						primario: () async {
							final dynamic r = await SupabaseConexion.cliente
									.from('perfiles')
									.select()
									.eq('id', usuarioId)
									.single();
							return r as Map<String, dynamic>;
						},
						fallback: () async {
							final dynamic r = await SupabaseConexion.cliente
									.from('usuarios')
									.select()
									.eq('id_usuario', usuarioId)
									.single();
							return r as Map<String, dynamic>;
						},
					);

			return Usuario.fromMap(respuesta);
		} catch (e) {
			throw Exception('Error al obtener usuario: $e');
		}
	}

	// Obtener usuario por nombre de usuario
	Future<Usuario?> obtenerPorNombreUsuario(String nombreUsuario) async {
		try {
			final List<dynamic> respuesta = await _conFallbackEsquema<List<dynamic>>(
				primario: () async {
					final dynamic r = await SupabaseConexion.cliente
							.from('perfiles')
							.select()
							.eq('nombre_usuario', nombreUsuario);
					return r as List<dynamic>;
				},
				fallback: () async {
					final dynamic r = await SupabaseConexion.cliente
							.from('usuarios')
							.select()
							.eq('nombre_usuario', nombreUsuario);
					return r as List<dynamic>;
				},
			);

			if (respuesta.isEmpty) {
				return null;
			}

			return Usuario.fromMap(respuesta[0]);
		} catch (e) {
			throw Exception('Error al buscar usuario: $e');
		}
	}

	// Guardar/actualizar perfil (devuelve Usuario)
	Future<Usuario> guardarPerfil({
		required String id,
		String? nombre,
		String? apellidos,
		String? nombreUsuario,
		String? correo,
		String? telefono,
		String? direccion,
		String? numero,
		String? localidad,
		String? provincia,
		String? codigoPostal,
		String? fechaNacimiento,
	}) async {
		try {
			final Map<String, dynamic> respuesta =
					await _conFallbackEsquema<Map<String, dynamic>>(
						primario: () async {
							final dynamic r = await SupabaseConexion.cliente
									.from('perfiles')
									.upsert(<String, dynamic>{
										'id': id,
										'nombre': nombre,
										'apellidos': apellidos,
										'nombre_usuario': nombreUsuario,
										'correo': correo,
										'telefono': telefono,
										'direccion': direccion,
										'numero': numero,
										'localidad': localidad,
										'provincia': provincia,
										'codigo_postal': codigoPostal,
										'fecha_nacimiento': fechaNacimiento,
										'actualizado_en': DateTime.now().toIso8601String(),
									})
									.select()
									.single();
							return r as Map<String, dynamic>;
						},
						fallback: () async {
							final dynamic r = await SupabaseConexion.cliente
									.from('usuarios')
									.upsert(<String, dynamic>{
										'id_usuario': id,
										'nombre': nombre,
										'nombre_usuario': nombreUsuario,
										'email': correo,
										'foto_url': null,
										'actualizado_en': DateTime.now().toIso8601String(),
									})
									.select()
									.single();
							return r as Map<String, dynamic>;
						},
					);

			return Usuario.fromMap(respuesta);
		} catch (e) {
			throw Exception('Error al guardar perfil: $e');
		}
	}

	// Actualizar perfil (devuelve Usuario)
	Future<Usuario> actualizarPerfil({
		required String usuarioId,
		String? nombre,
		String? apellidos,
		String? nombreUsuario,
		String? telefono,
		String? direccion,
		String? numero,
		String? localidad,
		String? provincia,
		String? codigoPostal,
		String? fechaNacimiento,
	}) async {
		try {
			final Map<String, dynamic> respuesta =
					await _conFallbackEsquema<Map<String, dynamic>>(
						primario: () async {
							final Map<String, dynamic> datos = <String, dynamic>{
								'actualizado_en': DateTime.now().toIso8601String(),
							};

							if (nombre != null) datos['nombre'] = nombre;
							if (apellidos != null) datos['apellidos'] = apellidos;
							if (nombreUsuario != null) {
								datos['nombre_usuario'] = nombreUsuario;
							}
							if (telefono != null) datos['telefono'] = telefono;
							if (direccion != null) datos['direccion'] = direccion;
							if (numero != null) datos['numero'] = numero;
							if (localidad != null) datos['localidad'] = localidad;
							if (provincia != null) datos['provincia'] = provincia;
							if (codigoPostal != null) {
								datos['codigo_postal'] = codigoPostal;
							}
							if (fechaNacimiento != null) {
								datos['fecha_nacimiento'] = fechaNacimiento;
							}

							final dynamic r = await SupabaseConexion.cliente
									.from('perfiles')
									.update(datos)
									.eq('id', usuarioId)
									.select()
									.single();
							return r as Map<String, dynamic>;
						},
						fallback: () async {
							final Map<String, dynamic> datos = <String, dynamic>{
								'actualizado_en': DateTime.now().toIso8601String(),
							};
							if (nombre != null) datos['nombre'] = nombre;
							if (nombreUsuario != null) {
								datos['nombre_usuario'] = nombreUsuario;
							}

							final dynamic r = await SupabaseConexion.cliente
									.from('usuarios')
									.update(datos)
									.eq('id_usuario', usuarioId)
									.select()
									.single();
							return r as Map<String, dynamic>;
						},
					);

			return Usuario.fromMap(respuesta);
		} catch (e) {
			throw Exception('Error al actualizar perfil: $e');
		}
	}

	// Eliminar usuario
	Future<void> eliminar(String usuarioId) async {
		try {
			await _conFallbackEsquema<void>(
				primario: () async {
					await SupabaseConexion.cliente
							.from('perfiles')
							.delete()
							.eq('id', usuarioId);
				},
				fallback: () async {
					await SupabaseConexion.cliente
							.from('usuarios')
							.delete()
							.eq('id_usuario', usuarioId);
				},
			);
		} catch (e) {
			throw Exception('Error al eliminar usuario: $e');
		}
	}
}
