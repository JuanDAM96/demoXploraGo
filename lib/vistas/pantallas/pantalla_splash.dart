import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final bool tieneSesion =
          SupabaseConexion.cliente.auth.currentUser != null;
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
            'assets/images/splash.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Icon(Icons.explore, size: 96, color: Colors.black);
            },
          ),
        ),
      ),
    );
  }
}
