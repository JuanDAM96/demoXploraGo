String obtenerIniciales(String nombre) {
	final List<String> partes = nombre.trim().split(' ');
	if (partes.isEmpty || partes.first.isEmpty) return 'U';
	if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
	return '${partes[0].substring(0, 1)}${partes[1].substring(0, 1)}'
			.toUpperCase();
}
