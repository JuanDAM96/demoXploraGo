import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/vistas/widgets/bottom_bar.dart';
import 'package:xplorago/vistas/widgets/top_bar.dart';

VoidCallback irA(BuildContext context, String ruta) {
  return () => Navigator.pushNamed(context, ruta);
}

Future<void> cerrarSesionEIrAInicio(BuildContext context) async {
  await AuthServicio().cerrarSesion();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(
    context,
    RutasApp.inicio,
    (Route<dynamic> route) => false,
  );
}

List<TopBarMenuItem> menuPrincipal(BuildContext context) {
  return <TopBarMenuItem>[
    TopBarMenuItem(label: 'Inicio', onTap: irA(context, RutasApp.home)),
    TopBarMenuItem(label: 'Grupo', onTap: irA(context, RutasApp.grupo)),
    TopBarMenuItem(label: 'Usuario', onTap: irA(context, RutasApp.usuario)),
    TopBarMenuItem(label: 'Gastos', onTap: irA(context, RutasApp.gastos)),
    TopBarMenuItem(
      label: 'Salir',
      onTap: () => cerrarSesionEIrAInicio(context),
    ),
  ];
}

TopBar topBarPrincipal(BuildContext context, {String menuLabel = 'menu'}) {
  return TopBar(
    title: 'XploraGo',
    menuLabel: menuLabel,
    backgroundColor: AppColors.verdeOscuro,
    foregroundColor: AppColors.blanco,
    menuBackgroundColor: AppColors.blanco,
    menuTextColor: AppColors.verdeOscuro,
    menuItems: menuPrincipal(context),
  );
}

TopBar topBarAuth(
  BuildContext context, {
  required List<TopBarMenuItem> menuItems,
}) {
  return TopBar(
    title: 'XploraGo',
    menuLabel: '',
    menuItems: menuItems,
  );
}

List<TopBarMenuItem> menuLogin(BuildContext context) {
  return <TopBarMenuItem>[
    TopBarMenuItem(label: 'Inicio', onTap: irA(context, RutasApp.inicio)),
    TopBarMenuItem(label: 'Registro', onTap: irA(context, RutasApp.registro)),
  ];
}

List<TopBarMenuItem> menuRegistro(BuildContext context) {
  return <TopBarMenuItem>[
    TopBarMenuItem(label: 'Inicio', onTap: irA(context, RutasApp.inicio)),
    TopBarMenuItem(label: 'Login', onTap: irA(context, RutasApp.login)),
  ];
}

BottomBar bottomBarPrincipal(
  BuildContext context, {
  required BottomBarItem? itemActivo,
  required String rutaAtras,
  bool mostrarChat = false,
  VoidCallback? onChat,
}) {
  return BottomBar(
    itemActivo: itemActivo,
    onAtras: irA(context, rutaAtras),
    onGrupo: irA(context, RutasApp.grupo),
    onGastos: irA(context, RutasApp.gastos),
    onPerfil: irA(context, RutasApp.usuario),
    mostrarChat: mostrarChat,
    onChat: onChat,
  );
}
