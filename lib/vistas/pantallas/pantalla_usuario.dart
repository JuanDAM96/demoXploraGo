import 'package:flutter/material.dart';
import 'package:xplorago/controladores/usuario_control.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/TopBar.dart';
import 'package:xplorago/vistas/widgets/BottomBar.dart';

class PantallaUsuario extends StatefulWidget {
  const PantallaUsuario({super.key});

  @override
  State<PantallaUsuario> createState() => _PantallaUsuarioState();
}

class _PantallaUsuarioState extends State<PantallaUsuario> {
  final UsuarioControl _usuarioControl = UsuarioControl();

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _usuarioControl.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    if (usuarioId == null) return;

    await _usuarioControl.cargarUsuario(usuarioId);
  }

  String _nombreVisible() {
    final String nombreUsuario =
        _usuarioControl.usuarioActual?.nombreUsuario?.trim() ?? '';
    final String nombre = _usuarioControl.usuarioActual?.nombre?.trim() ?? '';

    if (nombreUsuario.isNotEmpty) return nombreUsuario;
    if (nombre.isNotEmpty) return nombre;

    final String? metadataNombre = SupabaseConexion
        .cliente
        .auth
        .currentUser
        ?.userMetadata?['nombre_usuario']
        ?.toString();
    if (metadataNombre != null && metadataNombre.trim().isNotEmpty) {
      return metadataNombre.trim();
    }

    return 'Usuario';
  }

  String _fechaVisible() {
    final String fechaRaw =
        _usuarioControl.usuarioActual?.fechaNacimiento?.trim() ?? '';
    if (fechaRaw.isEmpty) return '--/--/----';

    final DateTime? fechaIso = DateTime.tryParse(fechaRaw);
    if (fechaIso == null) return fechaRaw;

    final String dia = fechaIso.day.toString().padLeft(2, '0');
    final String mes = fechaIso.month.toString().padLeft(2, '0');
    final String anio = fechaIso.year.toString();
    return '$dia/$mes/$anio';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: TopBar(
        title: 'XploraGo',
        menuLabel: 'menu',
        backgroundColor: AppColors.verdeOscuro,
        foregroundColor: AppColors.blanco,
        menuBackgroundColor: AppColors.blanco,
        menuTextColor: AppColors.verdeOscuro,
        leading: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/imagenes/logotopBar.png',
            fit: BoxFit.cover,
          ),
        ),
        menuItems: [
          TopBarMenuItem(
            label: 'Inicio',
            onTap: () => Navigator.pushNamed(context, RutasApp.home),
          ),
          TopBarMenuItem(
            label: 'Grupo',
            onTap: () => Navigator.pushNamed(context, RutasApp.grupo),
          ),
          TopBarMenuItem(
            label: 'Usuario',
            onTap: () => Navigator.pushNamed(context, RutasApp.usuario),
          ),
          TopBarMenuItem(
            label: 'Gastos',
            onTap: () => Navigator.pushNamed(context, RutasApp.gastos),
          ),
          TopBarMenuItem(
            label: 'Salir',
            onTap: () async {
              await AuthServicio().cerrarSesion();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                RutasApp.inicio,
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _usuarioControl,
        builder: (_, __) {
          return Stack(
            children: [
              Align(
                alignment: const Alignment(1.1, 0.55),
                child: Opacity(
                  opacity: 0.14,
                  child: Image.asset(
                    'assets/imagenes/fondo.png',
                    width: 280,
                    height: 280,
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _cargarUsuario,
                  color: AppColors.coral,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 118,
                          height: 132,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.verdeOscuro,
                              width: 4,
                            ),
                            color: AppColors.blanco,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            color: const Color(0xFFD4D8D8),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 66,
                              color: AppColors.verdeOscuro,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _nombreVisible(),
                          style: AppTextStyles.h1(
                            color: AppColors.verdeOscuro,
                          ).copyWith(fontSize: 34),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎂', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              _fechaVisible(),
                              style: AppTextStyles.h2(
                                color: AppColors.negro,
                              ).copyWith(fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                      if (_usuarioControl.cargando)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: LinearProgressIndicator(minHeight: 4),
                        ),
                      const SizedBox(height: 76),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _AccesoCard(
                            icon: Icons.groups_rounded,
                            onTap: () =>
                                Navigator.pushNamed(context, RutasApp.grupo),
                          ),
                          _AccesoCard(
                            icon: Icons.euro_rounded,
                            onTap: () =>
                                Navigator.pushNamed(context, RutasApp.gastos),
                          ),
                        ],
                      ),
                      const SizedBox(height: 92),
                      BottomBar(
                        itemActivo: BottomBarItem.grupo,
                        onAtras: () =>
                            Navigator.pushNamed(context, RutasApp.home),
                        onGrupo: () =>
                            Navigator.pushNamed(context, RutasApp.grupo),
                        onGastos: () =>
                            Navigator.pushNamed(context, RutasApp.gastos),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccesoCard extends StatelessWidget {
  const _AccesoCard({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 92,
        height: 74,
        decoration: BoxDecoration(
          color: AppColors.verdeOscuro,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 38, color: AppColors.blanco),
      ),
    );
  }
}
