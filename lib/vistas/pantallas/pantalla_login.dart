import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/TopBar.dart';

class PantallaLogin extends StatefulWidget {
	const PantallaLogin({super.key});

	@override
	State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
	final TextEditingController _correoController = TextEditingController();
	final TextEditingController _contrasenaController = TextEditingController();
	final AuthServicio _authServicio = AuthServicio();

	bool _cargando = false;

	@override
	void dispose() {
		_correoController.dispose();
		_contrasenaController.dispose();
		super.dispose();
	}

	Future<void> _iniciarSesion() async {
		final String correo = _correoController.text.trim();
		final String contrasena = _contrasenaController.text.trim();

		if (correo.isEmpty || contrasena.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Completa correo y contrasena.')),
			);
			return;
		}

		setState(() {
			_cargando = true;
		});

		try {
			await _authServicio.iniciarSesion(
				correo: correo,
				contrasena: contrasena,
			);

			if (!mounted) return;
			Navigator.pushNamedAndRemoveUntil(
				context,
				RutasApp.home,
				(Route<dynamic> route) => false,
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error al iniciar sesion: $e')),
			);
		} finally {
			if (mounted) {
				setState(() {
					_cargando = false;
				});
			}
		}
	}

	Future<void> _recuperarContrasena() async {
		final String correo = _correoController.text.trim();

		if (correo.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Escribe tu correo para recuperar la contrasena.')),
			);
			return;
		}

		try {
			await _authServicio.recuperarContrasena(correo: correo);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Te enviamos un correo para restablecer tu contrasena.')),
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('No se pudo enviar el correo: $e')),
			);
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
					TopBarMenuItem(label: 'Registro', onTap: () => Navigator.pushNamed(context, RutasApp.registro)),
				],
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
				child: Column(
					children: [
						const SizedBox(height: 10),
						Stack(
							alignment: Alignment.center,
							children: [
								Opacity(
									opacity: 0.25,
									child: Image.asset(
										'assets/imagenes/fondoInicio.png',
										height: 290,
										fit: BoxFit.contain,
										errorBuilder: (_, __, ___) => const SizedBox(height: 290),
									),
								),
								Column(
									children: [
										Image.asset(
											'assets/imagenes/splash.png',
											height: 150,
											fit: BoxFit.contain,
											errorBuilder: (_, __, ___) => const Icon(Icons.explore, size: 90),
										),
										const SizedBox(height: 10),
										Image.asset(
											'assets/imagenes/logotopBar.png',
											height: 42,
											fit: BoxFit.contain,
											errorBuilder: (_, __, ___) {
												return Text(
													'XploraGo',
													style: AppTextStyles.h2(color: const Color(0xFF1E2C56)).copyWith(
														fontStyle: FontStyle.italic,
													),
												);
											},
										),
									],
								),
							],
						),
						const SizedBox(height: 12),
						TextField(
							controller: _correoController,
							keyboardType: TextInputType.emailAddress,
							decoration: InputDecoration(
								hintText: 'Correo',
								hintStyle: AppTextStyles.texto(color: AppColors.grisClaro),
								contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
								enabledBorder: OutlineInputBorder(
									borderRadius: BorderRadius.circular(16),
									borderSide: const BorderSide(color: AppColors.verdeClaro, width: 1.2),
								),
								focusedBorder: OutlineInputBorder(
									borderRadius: BorderRadius.circular(16),
									borderSide: const BorderSide(color: AppColors.verdeOscuro, width: 1.5),
								),
								filled: true,
								fillColor: AppColors.blanco,
							),
						),
						const SizedBox(height: 10),
						TextField(
							controller: _contrasenaController,
							obscureText: true,
							decoration: InputDecoration(
								hintText: 'Contraseña',
								hintStyle: AppTextStyles.texto(color: AppColors.grisClaro),
								contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
								enabledBorder: OutlineInputBorder(
									borderRadius: BorderRadius.circular(16),
									borderSide: const BorderSide(color: AppColors.verdeClaro, width: 1.2),
								),
								focusedBorder: OutlineInputBorder(
									borderRadius: BorderRadius.circular(16),
									borderSide: const BorderSide(color: AppColors.verdeOscuro, width: 1.5),
								),
								filled: true,
								fillColor: AppColors.blanco,
							),
						),
						const SizedBox(height: 6),
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								Text(
									'¿No recuerdas la contraseña? ',
									style: AppTextStyles.microEtiqueta(color: AppColors.negro),
								),
								GestureDetector(
									onTap: _recuperarContrasena,
									child: Text(
										'Recuperar',
										style: AppTextStyles.microEtiqueta(color: AppColors.coral).copyWith(
											decoration: TextDecoration.underline,
										),
									),
								),
								Text(
									'  |  ',
									style: AppTextStyles.microEtiqueta(color: AppColors.grisClaro),
								),
								GestureDetector(
									onTap: () {
										Navigator.pushNamed(context, RutasApp.cambiarContrasena);
									},
									child: Text(
										'Cambiar',
										style: AppTextStyles.microEtiqueta(color: AppColors.coral).copyWith(
											decoration: TextDecoration.underline,
										),
									),
								),
							],
						),
						const SizedBox(height: 34),
						SizedBox(
							width: 130,
							height: 40,
							child: FilledButton(
								style: FilledButton.styleFrom(
									backgroundColor: AppColors.verdeOscuro,
									foregroundColor: AppColors.blanco,
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(30),
									),
								),
								onPressed: _cargando ? null : _iniciarSesion,
								child: _cargando
									? const SizedBox(
										height: 18,
										width: 18,
										child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanco),
									)
									: Text('Entrar', style: AppTextStyles.boton(color: AppColors.blanco)),
							),
						),
						const SizedBox(height: 20),
					],
				),
			),
		);
	}
}
