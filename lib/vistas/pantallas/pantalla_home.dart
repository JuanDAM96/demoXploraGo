import 'package:flutter/material.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/top_bar.dart';
import 'package:xplorago/vistas/widgets/bottom_bar.dart';

class PantallaHome extends StatefulWidget {
  const PantallaHome({super.key});

  @override
  State<PantallaHome> createState() => _PantallaHomeState();
}

class _PantallaHomeState extends State<PantallaHome> {
  final GrupoControl _grupoControl = GrupoControl();
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  @override
  void dispose() {
    _grupoControl.dispose();
    super.dispose();
  }

  Future<void> _cargarGrupos() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    if (usuarioId == null) {
      if (!mounted) return;
      setState(() {
        _mensaje = 'Inicia sesion para ver tus viajes.';
      });
      return;
    }

    await _grupoControl.cargarGrupos(usuarioId);

    if (_grupoControl.error != null) {
      if (!mounted) return;
      setState(() {
        _mensaje = _grupoControl.error;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _mensaje = null;
    });
  }

  void _unirseAGrupo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proximamente: unirse por codigo de invitacion'),
      ),
    );
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: BottomBar(
            itemActivo: null,
            onAtras: () => Navigator.pushNamed(context, RutasApp.inicio),
            onGrupo: () => Navigator.pushNamed(context, RutasApp.grupo),
            onGastos: () => Navigator.pushNamed(context, RutasApp.gastos),
            onPerfil: () => Navigator.pushNamed(context, RutasApp.usuario),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _grupoControl,
        builder: (context, child) {
          final List<dynamic> grupos = _grupoControl.grupos;
          final dynamic principal = grupos.isNotEmpty ? grupos.first : null;
          final dynamic secundario = grupos.length > 1 ? grupos[1] : null;

          return Stack(
            children: [
              Align(
                alignment: const Alignment(0, 0.02),
                child: Opacity(
                  opacity: 0.14,
                  child: Image.asset(
                    'assets/imagenes/fondo.png',
                    width: 260,
                    height: 260,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _cargarGrupos,
                  color: AppColors.coral,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                    children: [
                      Text(
                        'Tus Grupos:',
                        style: AppTextStyles.h2(
                          color: AppColors.negro,
                        ).copyWith(fontSize: 36 - 2),
                      ),
                      const SizedBox(height: 10),
                      if (principal != null)
                        _GrupoCard(
                          titulo: principal.nombre,
                          destino:
                              (principal.destino?.trim().isNotEmpty == true)
                              ? principal.destino!.trim()
                              : 'Sin destino',
                          miembros: principal.miembrosCount ?? 0,
                          activo: true,
                          imagePath: 'assets/imagenes/fondoInicio.png',
                          onTap: () =>
                              Navigator.pushNamed(context, RutasApp.grupo),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.blanco,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grisClaro),
                          ),
                          child: Text(
                            'Aun no tienes grupos creados o unidos.',
                            style: AppTextStyles.texto(color: AppColors.negro),
                          ),
                        ),
                      const SizedBox(height: 26),
                      Text(
                        'Ultimos Grupos:',
                        style: AppTextStyles.h2(
                          color: AppColors.negro,
                        ).copyWith(fontSize: 36 - 2),
                      ),
                      const SizedBox(height: 10),
                      if (secundario != null)
                        _GrupoCard(
                          titulo: secundario.nombre,
                          destino:
                              (secundario.destino?.trim().isNotEmpty == true)
                              ? secundario.destino!.trim()
                              : 'Sin destino',
                          miembros: secundario.miembrosCount ?? 0,
                          activo: false,
                          imagePath: 'assets/imagenes/splash.png',
                          onTap: () =>
                              Navigator.pushNamed(context, RutasApp.grupo),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.blanco,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grisClaro),
                          ),
                          child: Text(
                            'No hay mas grupos para mostrar.',
                            style: AppTextStyles.texto(color: AppColors.negro),
                          ),
                        ),
                      if (_grupoControl.cargando)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: LinearProgressIndicator(minHeight: 4),
                        ),
                      if (_mensaje != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _mensaje!,
                            style: AppTextStyles.texto(
                              color: AppColors.coralFuerte,
                            ),
                          ),
                        ),
                      const SizedBox(height: 88),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.verdeOscuro,
                                  foregroundColor: AppColors.blanco,
                                ),
                                onPressed: _unirseAGrupo,
                                child: Text(
                                  'Unirse a grupo',
                                  style: AppTextStyles.boton(
                                    color: AppColors.blanco,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.coral,
                                  side: const BorderSide(
                                    color: AppColors.coral,
                                    width: 2,
                                  ),
                                ),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  RutasApp.crearGrupo,
                                ),
                                child: Text(
                                  'Crear Grupo',
                                  style: AppTextStyles.boton(
                                    color: AppColors.coral,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
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

class _GrupoCard extends StatelessWidget {
  const _GrupoCard({
    required this.titulo,
    required this.destino,
    required this.miembros,
    required this.activo,
    required this.imagePath,
    required this.onTap,
  });

  final String titulo;
  final String destino;
  final int miembros;
  final bool activo;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fondo = activo
        ? const Color(0xFF7CB62C)
        : const Color(0xFF87A96B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.verdeOscuro, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.landscape_rounded),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h2(color: AppColors.blanco),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Destino: $destino',
                    style: AppTextStyles.texto(
                      color: AppColors.blanco,
                    ).copyWith(fontSize: 28 - 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Miembros: $miembros',
                    style: AppTextStyles.texto(
                      color: AppColors.blanco,
                    ).copyWith(fontSize: 28 - 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
