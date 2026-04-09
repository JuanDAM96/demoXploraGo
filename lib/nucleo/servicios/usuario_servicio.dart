import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';

class UsuarioServicio {
	// Obtener usuario por ID
	Future<Usuario> obtenerPorId(String usuarioId) async {
		try {
			final respuesta = await SupabaseConexion.cliente
					.from('perfiles')
					.select()
					.eq('id', usuarioId)
					.single();

		return Usuario.fromMap(respuesta);
		} catch (e) {
			throw Exception('Error al obtener usuario: $e');
		}
	}

	// Obtener usuario por nombre de usuario
	Future<Usuario?> obtenerPorNombreUsuario(String nombreUsuario) async {
		try {
			final respuesta = await SupabaseConexion.cliente
					.from('perfiles')
					.select()
					.eq('nombre_usuario', nombreUsuario);

			if ((respuesta as List<dynamic>).isEmpty) {
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
			final respuesta = await SupabaseConexion.cliente
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
			final datos = <String, dynamic>{
				'actualizado_en': DateTime.now().toIso8601String(),
			};

			if (nombre != null) datos['nombre'] = nombre;
			if (apellidos != null) datos['apellidos'] = apellidos;
			if (nombreUsuario != null) datos['nombre_usuario'] = nombreUsuario;
			if (telefono != null) datos['telefono'] = telefono;
			if (direccion != null) datos['direccion'] = direccion;
			if (numero != null) datos['numero'] = numero;
			if (localidad != null) datos['localidad'] = localidad;
			if (provincia != null) datos['provincia'] = provincia;
			if (codigoPostal != null) datos['codigo_postal'] = codigoPostal;
			if (fechaNacimiento != null) datos['fecha_nacimiento'] = fechaNacimiento;

			final respuesta = await SupabaseConexion.cliente
					.from('perfiles')
					.update(datos)
					.eq('id', usuarioId)
					.select()
					.single();

			return Usuario.fromMap(respuesta);
		} catch (e) {
			throw Exception('Error al actualizar perfil: $e');
		}
	}

	// Eliminar usuario
	Future<void> eliminar(String usuarioId) async {
		try {
			await SupabaseConexion.cliente
					.from('perfiles')
					.delete()
					.eq('id', usuarioId);
		} catch (e) {
			throw Exception('Error al eliminar usuario: $e');
		}
	}
}
