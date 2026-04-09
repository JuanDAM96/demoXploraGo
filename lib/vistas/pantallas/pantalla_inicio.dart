import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';

class PantallaInicio extends StatelessWidget {
	const PantallaInicio({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.fondo,
			body: SafeArea(
				child: Center(
					child: Container(
						width: 290,
						padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
						decoration: const BoxDecoration(
							color: Color(0xFFAECED1),
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Image.asset(
									'assets/imagenes/fondoInicio.png',
									height: 300,
									fit: BoxFit.contain,
									errorBuilder: (_, __, ___) {
										return Container(
											height: 300,
											width: 300,
											decoration: BoxDecoration(
												shape: BoxShape.circle,
												color: AppColors.blanco.withValues(alpha: 0.4),
											),
											child: const Icon(Icons.landscape, size: 96),
										);
									},
								),
								const SizedBox(height: 22),
								SizedBox(
									width: 155,
									height: 38,
									child: FilledButton(
										style: FilledButton.styleFrom(
											backgroundColor: AppColors.verdeOscuro,
											foregroundColor: AppColors.blanco,
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(30),
											),
										),
										onPressed: () {
											Navigator.pushNamed(context, RutasApp.login);
										},
										child: Text('Entrar', style: AppTextStyles.boton(color: AppColors.blanco)),
									),
								),
								const SizedBox(height: 12),
								SizedBox(
									width: 155,
									height: 36,
									child: OutlinedButton(
										style: OutlinedButton.styleFrom(
											foregroundColor: AppColors.coral,
											side: const BorderSide(color: AppColors.coral, width: 3),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(30),
											),
										),
										onPressed: () {
											Navigator.pushNamed(context, RutasApp.registro);
										},
										child: Text('Crear Cuenta', style: AppTextStyles.boton(color: AppColors.coral)),
									),
								),
								const SizedBox(height: 14),
							],
						),
					),
				),
			),
		);
	}
}
