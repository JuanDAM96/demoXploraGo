import 'package:supabase_flutter/supabase_flutter.dart';

import 'config_db.dart';

class SupabaseConexion {
  static Future<void>? _inicializacionFuture;

  static SupabaseClient get cliente => Supabase.instance.client;

  static Future<void> inicializar() {
    return _inicializacionFuture ??= Supabase.initialize(
      url: ConfigDB.url,
      anonKey: ConfigDB.anonKey,
    );
  }
}
