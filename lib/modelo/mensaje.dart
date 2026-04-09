class Mensaje {
	const Mensaje({
		required this.id,
		required this.grupoId,
		required this.usuarioId,
		required this.texto,
		this.creadoEn,
		this.leido = false,
	});

	final String id;
	final String grupoId;
	final String usuarioId;
	final String texto;
	final DateTime? creadoEn;
	final bool leido;

	Mensaje copyWith({
		String? id,
		String? grupoId,
		String? usuarioId,
		String? texto,
		DateTime? creadoEn,
		bool? leido,
	}) {
		return Mensaje(
			id: id ?? this.id,
			grupoId: grupoId ?? this.grupoId,
			usuarioId: usuarioId ?? this.usuarioId,
			texto: texto ?? this.texto,
			creadoEn: creadoEn ?? this.creadoEn,
			leido: leido ?? this.leido,
		);
	}

	factory Mensaje.fromMap(Map<String, dynamic> map) {
		return Mensaje(
			id: (map['id'] ?? '').toString(),
			grupoId: (map['grupo_id'] ?? '').toString(),
			usuarioId: (map['usuario_id'] ?? '').toString(),
			texto: (map['texto'] ?? '').toString(),
			creadoEn: _parseFecha(map['creado_en']),
			leido: map['leido'] == true,
		);
	}

	Map<String, dynamic> toMap() {
		return <String, dynamic>{
			'id': id,
			'grupo_id': grupoId,
			'usuario_id': usuarioId,
			'texto': texto,
			'creado_en': creadoEn?.toIso8601String(),
			'leido': leido,
		};
	}

	static DateTime? _parseFecha(dynamic value) {
		if (value == null) return null;
		return DateTime.tryParse(value.toString());
	}
}
