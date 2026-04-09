class Usuario {
	const Usuario({
		required this.id,
		this.nombre,
		this.apellidos,
		this.nombreUsuario,
		this.correo,
		this.telefono,
		this.direccion,
		this.numero,
		this.localidad,
		this.provincia,
		this.codigoPostal,
		this.fechaNacimiento,
		this.creadoEn,
		this.actualizadoEn,
	});

	final String id;
	final String? nombre;
	final String? apellidos;
	final String? nombreUsuario;
	final String? correo;
	final String? telefono;
	final String? direccion;
	final String? numero;
	final String? localidad;
	final String? provincia;
	final String? codigoPostal;
	final String? fechaNacimiento;
	final DateTime? creadoEn;
	final DateTime? actualizadoEn;

	Usuario copyWith({
		String? id,
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
		DateTime? creadoEn,
		DateTime? actualizadoEn,
	}) {
		return Usuario(
			id: id ?? this.id,
			nombre: nombre ?? this.nombre,
			apellidos: apellidos ?? this.apellidos,
			nombreUsuario: nombreUsuario ?? this.nombreUsuario,
			correo: correo ?? this.correo,
			telefono: telefono ?? this.telefono,
			direccion: direccion ?? this.direccion,
			numero: numero ?? this.numero,
			localidad: localidad ?? this.localidad,
			provincia: provincia ?? this.provincia,
			codigoPostal: codigoPostal ?? this.codigoPostal,
			fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
			creadoEn: creadoEn ?? this.creadoEn,
			actualizadoEn: actualizadoEn ?? this.actualizadoEn,
		);
	}

	factory Usuario.fromMap(Map<String, dynamic> map) {
		return Usuario(
			id: (map['id'] ?? '').toString(),
			nombre: map['nombre']?.toString(),
			apellidos: map['apellidos']?.toString(),
			nombreUsuario: map['nombre_usuario']?.toString(),
			correo: map['correo']?.toString(),
			telefono: map['telefono']?.toString(),
			direccion: map['direccion']?.toString(),
			numero: map['numero']?.toString(),
			localidad: map['localidad']?.toString(),
			provincia: map['provincia']?.toString(),
			codigoPostal: map['codigo_postal']?.toString(),
			fechaNacimiento: map['fecha_nacimiento']?.toString(),
			creadoEn: _parseFecha(map['creado_en']),
			actualizadoEn: _parseFecha(map['actualizado_en']),
		);
	}

	Map<String, dynamic> toMap() {
		return <String, dynamic>{
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
			'creado_en': creadoEn?.toIso8601String(),
			'actualizado_en': actualizadoEn?.toIso8601String(),
		};
	}

	static DateTime? _parseFecha(dynamic value) {
		if (value == null) return null;
		return DateTime.tryParse(value.toString());
	}
}
