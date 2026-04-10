import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/temas/tema_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseConexion.inicializar();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'XploraGo',
      theme: AppTheme.light(),
      initialRoute: RutasApp.splash,
      routes: RutasApp.rutas,
    );
  }
}
