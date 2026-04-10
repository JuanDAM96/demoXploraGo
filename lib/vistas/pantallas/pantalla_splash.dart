import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> {
  bool _sesionActivaLocal() {
    final session = SupabaseConexion.cliente.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      return false;
    }

    final int? expiresAt = session.expiresAt;
    if (expiresAt == null) return true;

    final DateTime expiraEn = DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
    );

    return expiraEn.isAfter(DateTime.now());
  }

  Future<bool> _sesionRemotaValida() async {
    if (!_sesionActivaLocal()) return false;

    try {
      final respuesta = await SupabaseConexion.cliente.auth.getUser();
      return respuesta.user != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      await SupabaseConexion.inicializar();

      bool tieneSesion = await _sesionRemotaValida();
      if (!tieneSesion) {
        // Limpia posibles restos de sesión local para no redirigir mal.
        await SupabaseConexion.cliente.auth.signOut();
        tieneSesion = false;
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        tieneSesion ? RutasApp.home : RutasApp.inicio,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Image.asset(
            'assets/imagenes/splash.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.explore, size: 96, color: Colors.black);
            },
          ),
        ),
      ),
    );
  }
}
