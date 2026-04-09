class Actividad {
	const Actividad({
		required this.id,
		required this.grupoId,
		required this.titulo,
		this.descripcion,
		this.lugar,
		this.fechaActividad,
		this.costo,
		this.creadoPor,
		this.completada = false,
	});

	final String id;
	final String grupoId;
	final String titulo;
	final String? descripcion;
	final String? lugar;
	final DateTime? fechaActividad;
	final double? costo;
	final String? creadoPor;
	final bool completada;

	Actividad copyWith({
		String? id,
		String? grupoId,
		String? titulo,
		String? descripcion,
		String? lugar,
		DateTime? fechaActividad,
		double? costo,
		String? creadoPor,
		bool? completada,
	}) {
		return Actividad(
			id: id ?? this.id,
			grupoId: grupoId ?? this.grupoId,
			titulo: titulo ?? this.titulo,
			descripcion: descripcion ?? this.descripcion,
			lugar: lugar ?? this.lugar,
			fechaActividad: fechaActividad ?? this.fechaActividad,
			costo: costo ?? this.costo,
			creadoPor: creadoPor ?? this.creadoPor,
			completada: completada ?? this.completada,
		);
	}

	factory Actividad.fromMap(Map<String, dynamic> map) {
		return Actividad(
			id: (map['id'] ?? '').toString(),
			grupoId: (map['grupo_id'] ?? '').toString(),
			titulo: (map['titulo'] ?? '').toString(),
			descripcion: map['descripcion']?.toString(),
			lugar: map['lugar']?.toString(),
			fechaActividad: _parseFecha(map['fecha_actividad']),
			costo: (map['costo'] as num?)?.toDouble(),
			creadoPor: map['creado_por']?.toString(),
			completada: map['completada'] == true,
		);
	}

	Map<String, dynamic> toMap() {
		return <String, dynamic>{
			'id': id,
			'grupo_id': grupoId,
			'titulo': titulo,
			'descripcion': descripcion,
			'lugar': lugar,
			'fecha_actividad': fechaActividad?.toIso8601String(),
			'costo': costo,
			'creado_por': creadoPor,
			'completada': completada,
		};
	}

	static DateTime? _parseFecha(dynamic value) {
		if (value == null) return null;
		return DateTime.tryParse(value.toString());
	}
}
