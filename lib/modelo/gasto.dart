class Gasto {
	const Gasto({
		required this.id,
		required this.grupoId,
		required this.descripcion,
		required this.monto,
		required this.pagadoPor,
		this.fecha,
		this.divididoEntre = const <String>[],
	});

	final String id;
	final String grupoId;
	final String descripcion;
	final double monto;
	final String pagadoPor;
	final DateTime? fecha;
	final List<String> divididoEntre;

	Gasto copyWith({
		String? id,
		String? grupoId,
		String? descripcion,
		double? monto,
		String? pagadoPor,
		DateTime? fecha,
		List<String>? divididoEntre,
	}) {
		return Gasto(
			id: id ?? this.id,
			grupoId: grupoId ?? this.grupoId,
			descripcion: descripcion ?? this.descripcion,
			monto: monto ?? this.monto,
			pagadoPor: pagadoPor ?? this.pagadoPor,
			fecha: fecha ?? this.fecha,
			divididoEntre: divididoEntre ?? this.divididoEntre,
		);
	}

	factory Gasto.fromMap(Map<String, dynamic> map) {
		return Gasto(
			id: (map['id'] ?? '').toString(),
			grupoId: (map['grupo_id'] ?? '').toString(),
			descripcion: (map['descripcion'] ?? '').toString(),
			monto: ((map['monto'] as num?) ?? 0).toDouble(),
			pagadoPor: (map['pagado_por'] ?? '').toString(),
			fecha: _parseFecha(map['fecha']),
			divididoEntre: (map['dividido_entre'] as List<dynamic>?)
							?.map((dynamic e) => e.toString())
							.toList() ??
					<String>[],
		);
	}

	Map<String, dynamic> toMap() {
		return <String, dynamic>{
			'id': id,
			'grupo_id': grupoId,
			'descripcion': descripcion,
			'monto': monto,
			'pagado_por': pagadoPor,
			'fecha': fecha?.toIso8601String(),
			'dividido_entre': divididoEntre,
		};
	}

	static DateTime? _parseFecha(dynamic value) {
		if (value == null) return null;
		return DateTime.tryParse(value.toString());
	}
}
