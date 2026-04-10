import 'package:flutter/material.dart';
import 'package:xplorago/vistas/pantallas/pagina_gasto.dart';
import 'package:xplorago/vistas/pantallas/pantalla_cambiar_contrasena.dart';
import 'package:xplorago/vistas/pantallas/pantalla_chat.dart';
import 'package:xplorago/vistas/pantallas/pantalla_crear_grupo.dart';
import 'package:xplorago/vistas/pantallas/pantalla_grupos.dart';
import 'package:xplorago/vistas/pantallas/pantalla_home.dart';
import 'package:xplorago/vistas/pantallas/pantalla_inicio.dart';
import 'package:xplorago/vistas/pantallas/pantalla_login.dart';
import 'package:xplorago/vistas/pantallas/pantalla_registro.dart';
import 'package:xplorago/vistas/pantallas/pantalla_splash.dart';
import 'package:xplorago/vistas/pantallas/pantalla_usuario.dart';

class RutasApp {
  static const String splash = '/splash';
  static const String inicio = '/inicio';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String home = '/home';
  static const String usuario = '/usuario';
  static const String grupo = '/grupo';
  static const String chat = '/chat';
  static const String gastos = '/gastos';
  static const String crearGrupo = '/crear-grupo';
  static const String cambiarContrasena = '/cambiar-contrasena';

  static Map<String, WidgetBuilder> get rutas => <String, WidgetBuilder>{
        splash: (_) => const PantallaSplash(),
        inicio: (_) => const PantallaInicio(),
        login: (_) => const PantallaLogin(),
        registro: (_) => const PantallaRegistro(),
        home: (_) => const PantallaHome(),
        usuario: (_) => const PantallaUsuario(),
        grupo: (_) => const PantallaGrupos(),
        chat: (_) => const PantallaChat(),
        gastos: (_) => const PaginaGasto(),
        crearGrupo: (_) => const PantallaCrearGrupo(),
        cambiarContrasena: (_) => const PantallaCambiarContrasena(),
      };
}
