import 'package:supabase_flutter/supabase_flutter.dart';
import 'ConfigDB.dart';

class SupabaseConexion {

  static final SupabaseClient cliente = Supabase.instance.client;

  static Future inicializar() async {
    await Supabase.initialize(
      url: ConfigDB.url,
      anonKey: ConfigDB.anonKey,
    );
  }
}