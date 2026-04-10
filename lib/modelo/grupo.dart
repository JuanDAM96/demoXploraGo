class Grupo {
	const Grupo({
		required this.id,
		required this.nombre,
		this.destino,
		this.descripcion,
		this.creadorId,
		this.miembrosCount,
		this.creadoEn,
		this.actualizadoEn,
	});

	final String id;
	final String nombre;
	final String? destino;
	final String? descripcion;
	final String? creadorId;
	final int? miembrosCount;
	final DateTime? creadoEn;
	final DateTime? actualizadoEn;

	Grupo copyWith({
		String? id,
		String? nombre,
		String? destino,
		String? descripcion,
		String? creadorId,
		int? miembrosCount,
		DateTime? creadoEn,
		DateTime? actualizadoEn,
	}) {
		return Grupo(
			id: id ?? this.id,
			nombre: nombre ?? this.nombre,
			destino: destino ?? this.destino,
			descripcion: descripcion ?? this.descripcion,
			creadorId: creadorId ?? this.creadorId,
			miembrosCount: miembrosCount ?? this.miembrosCount,
			creadoEn: creadoEn ?? this.creadoEn,
			actualizadoEn: actualizadoEn ?? this.actualizadoEn,
		);
	}

	factory Grupo.fromMap(Map<String, dynamic> map) {
		final dynamic miembros = map['miembros'];
		final int? miembrosDesdeJoin = miembros is List<dynamic>
				? miembros.length
				: null;

		return Grupo(
			id: (map['id_grupo'] ?? map['id'] ?? '').toString(),
			nombre: (map['nombre'] ?? '').toString(),
			destino: map['destino']?.toString(),
			descripcion: map['descripcion']?.toString(),
			creadorId: map['creador_id']?.toString(),
			miembrosCount:
				miembrosDesdeJoin ?? (map['miembros_count'] as num?)?.toInt(),
			creadoEn: _parseFecha(map['creado_el'] ?? map['creado_en']),
			actualizadoEn: _parseFecha(map['actualizado_en']),
		);
	}

	Map<String, dynamic> toMap() {
		return <String, dynamic>{
			'nombre': nombre,
			'destino': destino,
			'descripcion': descripcion,
		};
	}

	static DateTime? _parseFecha(dynamic value) {
		if (value == null) return null;
		return DateTime.tryParse(value.toString());
	}
}
