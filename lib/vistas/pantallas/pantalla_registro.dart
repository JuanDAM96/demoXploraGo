import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/top_bar.dart';

class PantallaRegistro extends StatefulWidget {
	const PantallaRegistro({super.key});

	@override
	State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
	final TextEditingController _nombreController = TextEditingController();
	final TextEditingController _apellidosController = TextEditingController();
	final TextEditingController _nombreUsuarioController = TextEditingController();
	final TextEditingController _fechaNacimientoController = TextEditingController();
	final TextEditingController _correoController = TextEditingController();
	final TextEditingController _telefonoController = TextEditingController();
	final TextEditingController _direccionController = TextEditingController();
	final TextEditingController _numeroController = TextEditingController();
	final TextEditingController _localidadController = TextEditingController();
	final TextEditingController _provinciaController = TextEditingController();
	final TextEditingController _codigoPostalController = TextEditingController();
	final TextEditingController _contrasenaController = TextEditingController();
	final TextEditingController _repiteContrasenaController = TextEditingController();

	final AuthServicio _authServicio = AuthServicio();
	final UsuarioServicio _usuarioServicio = UsuarioServicio();

	bool _cargando = false;

	@override
	void dispose() {
		_nombreController.dispose();
		_apellidosController.dispose();
		_nombreUsuarioController.dispose();
		_fechaNacimientoController.dispose();
		_correoController.dispose();
		_telefonoController.dispose();
		_direccionController.dispose();
		_numeroController.dispose();
		_localidadController.dispose();
		_provinciaController.dispose();
		_codigoPostalController.dispose();
		_contrasenaController.dispose();
		_repiteContrasenaController.dispose();
		super.dispose();
	}

	Future<void> _crearCuenta() async {
		final String correo = _correoController.text.trim();
		final String contrasena = _contrasenaController.text.trim();
		final String repiteContrasena = _repiteContrasenaController.text.trim();

		if (correo.isEmpty || contrasena.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Correo y contrasena son obligatorios.')),
			);
			return;
		}

		if (contrasena != repiteContrasena) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Las contrasenas no coinciden.')),
			);
			return;
		}

		setState(() {
			_cargando = true;
		});

		try {
			final usuario = await _authServicio.registrar(
				correo: correo,
				contrasena: contrasena,
				nombreUsuario: _nombreUsuarioController.text.trim(),
			);

			try {
				await _usuarioServicio.guardarPerfil(
					id: usuario.id,
					nombre: _nombreController.text.trim(),
					apellidos: _apellidosController.text.trim(),
					nombreUsuario: _nombreUsuarioController.text.trim(),
					correo: correo,
					telefono: _telefonoController.text.trim(),
					direccion: _direccionController.text.trim(),
					numero: _numeroController.text.trim(),
					localidad: _localidadController.text.trim(),
					provincia: _provinciaController.text.trim(),
					codigoPostal: _codigoPostalController.text.trim(),
					fechaNacimiento: _fechaNacimientoController.text.trim(),
				);
			} catch (_) {
				if (mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(content: Text('Cuenta creada. Perfil no guardado aun.')),
					);
				}
			}

			if (!mounted) return;
			Navigator.pushReplacementNamed(context, RutasApp.home);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error al registrar: $e')),
			);
		} finally {
			if (mounted) {
				setState(() {
					_cargando = false;
				});
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.fondo,
			appBar: TopBar(
				title: 'XploraGo',
				menuLabel: '',
				menuItems: [
					TopBarMenuItem(label: 'Inicio', onTap: () => Navigator.pushNamed(context, RutasApp.inicio)),
					TopBarMenuItem(label: 'Login', onTap: () => Navigator.pushNamed(context, RutasApp.login)),
				],
			),
			body: Stack(
				children: [
					Center(
						child: Opacity(
							opacity: 0.14,
							child: Image.asset(
								'assets/imagenes/fondoInicio.png',
								height: 320,
								fit: BoxFit.contain,
								errorBuilder: (context, error, stackTrace) =>
									const SizedBox.shrink(),
							),
						),
					),
					SingleChildScrollView(
						padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Foto Perfil', style: AppTextStyles.etiqueta(color: AppColors.negro)),
								const SizedBox(height: 6),
								Container(
									height: 42,
									padding: const EdgeInsets.symmetric(horizontal: 10),
									decoration: BoxDecoration(
										color: AppColors.blanco,
										borderRadius: BorderRadius.circular(12),
										border: Border.all(color: AppColors.verdeClaro, width: 1.2),
									),
									child: Row(
										children: [
											const Icon(Icons.image_outlined, size: 16, color: AppColors.negro),
											const SizedBox(width: 8),
											Expanded(
												child: Text(
													'Sube tu foto',
													style: AppTextStyles.texto(color: AppColors.grisClaro),
												),
											),
											SizedBox(
												width: 64,
												height: 28,
												child: FilledButton(
													style: FilledButton.styleFrom(
														padding: EdgeInsets.zero,
														backgroundColor: AppColors.verdeOscuro,
														foregroundColor: AppColors.blanco,
														shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
													),
													onPressed: () {},
													child: Text('Subir', style: AppTextStyles.microEtiqueta(color: AppColors.blanco)),
												),
											),
										],
									),
								),
								const SizedBox(height: 12),
								Row(
									children: [
										Expanded(child: _CampoRegistro(label: 'Nombre', hint: 'Nombre', controller: _nombreController)),
										const SizedBox(width: 10),
										Expanded(child: _CampoRegistro(label: 'Apellidos', hint: 'Apellidos', controller: _apellidosController)),
									],
								),
								const SizedBox(height: 10),
								Row(
									children: [
										Expanded(
											child: _CampoRegistro(
												label: 'Nombre Usuario',
												hint: 'Nombre Usuario',
												controller: _nombreUsuarioController,
											),
										),
										const SizedBox(width: 10),
										Expanded(
											child: _CampoRegistro(
												label: 'Fecha de nacimiento',
												hint: '00/00/0000',
												icon: Icons.calendar_today_outlined,
												controller: _fechaNacimientoController,
											),
										),
									],
								),
								const SizedBox(height: 10),
								Row(
									children: [
										Expanded(
											child: _CampoRegistro(
												label: 'Correo electronico',
												hint: 'Correo electronico',
												controller: _correoController,
												keyboardType: TextInputType.emailAddress,
											),
										),
										const SizedBox(width: 10),
										Expanded(
											child: _CampoRegistro(
												label: 'Telefono',
												hint: '+34 000 000 000',
												controller: _telefonoController,
												keyboardType: TextInputType.phone,
											),
										),
									],
								),
								const SizedBox(height: 10),
								Row(
									children: [
										Expanded(
											flex: 3,
											child: _CampoRegistro(
												label: 'Direccion',
												hint: 'Direccion',
												controller: _direccionController,
											),
										),
										const SizedBox(width: 10),
										Expanded(
											flex: 1,
											child: _CampoRegistro(
												label: 'Numero',
												hint: 'Numero',
												controller: _numeroController,
											),
										),
									],
								),
								const SizedBox(height: 10),
								_CampoRegistro(label: 'Localidad', hint: 'Localidad', controller: _localidadController),
								const SizedBox(height: 10),
								Row(
									children: [
										Expanded(child: _CampoRegistro(label: 'Provincia', hint: 'Provincia', controller: _provinciaController)),
										const SizedBox(width: 10),
										Expanded(
											child: _CampoRegistro(
												label: 'Codigo Postal',
												hint: 'Codigo Postal',
												controller: _codigoPostalController,
											),
										),
									],
								),
								const SizedBox(height: 10),
								Row(
									children: [
										Expanded(
											child: _CampoRegistro(
												label: 'Contrasena',
												hint: 'Contrasena',
												obscureText: true,
												controller: _contrasenaController,
											),
										),
										const SizedBox(width: 10),
										Expanded(
											child: _CampoRegistro(
												label: 'Repite Contrasena',
												hint: 'Contrasena',
												obscureText: true,
												controller: _repiteContrasenaController,
											),
										),
									],
								),
								const SizedBox(height: 26),
								Center(
									child: SizedBox(
										width: 145,
										height: 42,
										child: OutlinedButton(
											style: OutlinedButton.styleFrom(
												foregroundColor: AppColors.coral,
												side: const BorderSide(color: AppColors.coral, width: 3),
												shape: RoundedRectangleBorder(
													borderRadius: BorderRadius.circular(30),
												),
											),
											onPressed: _cargando ? null : _crearCuenta,
											child: _cargando
												? const SizedBox(
													height: 18,
													width: 18,
													child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
												)
												: Text(
													'Crear Cuenta',
													style: AppTextStyles.boton(color: AppColors.coral),
												),
										),
									),
								),
							],
						),
					),
				],
			),
		);
	}
}

class _CampoRegistro extends StatelessWidget {
  const _CampoRegistro({
    required this.label,
    required this.hint,
		required this.controller,
    this.icon,
    this.obscureText = false,
		this.keyboardType,
  });

  final String label;
  final String hint;
	final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
	final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.etiqueta(color: AppColors.negro)),
        const SizedBox(height: 4),
        TextField(
					controller: controller,
          obscureText: obscureText,
					keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.texto(color: AppColors.grisClaro),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            prefixIcon: icon == null ? null : Icon(icon, size: 16, color: AppColors.negro),
            prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grisClaro, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.verdeOscuro, width: 1.2),
            ),
            filled: true,
            fillColor: AppColors.blanco,
          ),
        ),
      ],
    );
  }
}
