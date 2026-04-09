import 'package:flutter/material.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/TopBar.dart';
import 'package:xplorago/vistas/widgets/BottomBar.dart';

class PantallaGrupos extends StatefulWidget {
  const PantallaGrupos({super.key});

  @override
  State<PantallaGrupos> createState() => _PantallaGruposState();
}

class _PantallaGruposState extends State<PantallaGrupos> {
  final GrupoControl _grupoControl = GrupoControl();
  final UsuarioServicio _usuarioServicio = UsuarioServicio();

  List<_MiembroVista> _miembros = <_MiembroVista>[];
  bool _cargandoMiembros = false;

  @override
  void initState() {
    super.initState();
    _cargarGrupo();
  }

  @override
  void dispose() {
    _grupoControl.dispose();
    super.dispose();
  }

  Future<void> _cargarGrupo() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    if (usuarioId == null) return;

    await _grupoControl.cargarGrupos(usuarioId);
    if (_grupoControl.grupoActual == null && _grupoControl.grupos.isNotEmpty) {
      await _grupoControl.seleccionarGrupo(_grupoControl.grupos.first.id);
    }

    if (_grupoControl.grupoActual != null) {
      await _cargarMiembrosDelGrupo(
        grupoId: _grupoControl.grupoActual!.id,
        usuarioIdActual: usuarioId,
      );
    }
  }

  Future<void> _cargarMiembrosDelGrupo({
    required String grupoId,
    required String usuarioIdActual,
  }) async {
    if (!mounted) return;
    setState(() {
      _cargandoMiembros = true;
    });

    try {
      final List<String> ids = await _grupoControl.obtenerMiembroIds(grupoId);
      final Set<String> idsUnicos = <String>{...ids, usuarioIdActual};

      final String? creadorId = _grupoControl.grupoActual?.creadorId;
      if (creadorId != null && creadorId.isNotEmpty) {
        idsUnicos.add(creadorId);
      }

      final List<Usuario> usuarios = <Usuario>[];
      for (final String id in idsUnicos) {
        try {
          usuarios.add(await _usuarioServicio.obtenerPorId(id));
        } catch (_) {
          // Si un perfil no existe, lo omitimos para mantener la UI estable.
        }
      }

      const List<Color> palette = <Color>[
        Color(0xFFE9B2A3),
        Color(0xFFB9C8D8),
        Color(0xFFA3C89B),
        Color(0xFFE7C593),
      ];

      final List<_MiembroVista> miembros = usuarios.asMap().entries.map((
        entry,
      ) {
        final int index = entry.key;
        final Usuario usuario = entry.value;
        final String nombre = (usuario.nombreUsuario?.trim().isNotEmpty == true)
            ? usuario.nombreUsuario!.trim()
            : (usuario.nombre?.trim().isNotEmpty == true)
            ? usuario.nombre!.trim()
            : 'Usuario';

        return _MiembroVista(
          id: usuario.id,
          nombre: nombre,
          color: palette[index % palette.length],
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _miembros = miembros;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _cargandoMiembros = false;
      });
    }
  }

  Future<void> _mostrarDialogoAgregarMiembro() async {
    final String? grupoId = _grupoControl.grupoActual?.id;
    if (grupoId == null) return;

    final TextEditingController controller = TextEditingController();

    final String? nuevoMiembroId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar miembro'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'ID de usuario'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (nuevoMiembroId == null || nuevoMiembroId.isEmpty) return;

    try {
      await _grupoControl.agregarMiembro(grupoId, nuevoMiembroId);
      final String? usuarioIdActual =
          SupabaseConexion.cliente.auth.currentUser?.id;
      if (usuarioIdActual != null) {
        await _cargarMiembrosDelGrupo(
          grupoId: grupoId,
          usuarioIdActual: usuarioIdActual,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miembro agregado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo agregar: $e')));
    }
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
        animation: _grupoControl,
        builder: (_, __) {
          // Si no hay grupo actual, mostrar pantalla vacía
          if (_grupoControl.grupoActual == null) {
            return Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.verdeOscuro,
                          foregroundColor: AppColors.blanco,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, RutasApp.crearGrupo),
                        child: Text(
                          'Crear grupo',
                          style: AppTextStyles.boton(color: AppColors.blanco),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Si hay grupo, mostrar contenido del grupo
          final List<_MiembroVista> miembros = _miembros.take(2).toList();
          final String nombreGrupo =
              _grupoControl.grupoActual?.nombre.isNotEmpty == true
              ? _grupoControl.grupoActual!.nombre
              : 'Viaje Express';

          return Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.05),
                child: Opacity(
                  opacity: 0.14,
                  child: Image.asset(
                    'assets/imagenes/fondo.png',
                    width: 330,
                    height: 330,
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _cargarGrupo,
                  color: AppColors.coral,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.blanco,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.grisClaro.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/imagenes/fondoInicio.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$nombreGrupo:',
                              style: AppTextStyles.h2(
                                color: AppColors.negro,
                              ).copyWith(fontSize: 38),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Miembros:',
                        style: AppTextStyles.h2(
                          color: AppColors.negro,
                        ).copyWith(fontSize: 33 - 5),
                      ),
                      const SizedBox(height: 14),
                      if (_cargandoMiembros)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(minHeight: 4),
                        )
                      else if (miembros.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Todavia no hay miembros cargados.',
                            style: AppTextStyles.texto(
                              color: AppColors.grisClaro,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _MiembroCard(miembro: miembros[0])),
                            const SizedBox(width: 10),
                            Expanded(
                              child: miembros.length > 1
                                  ? _MiembroCard(miembro: miembros[1])
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionIcon(
                            icon: Icons.currency_exchange,
                            onTap: () =>
                                Navigator.pushNamed(context, RutasApp.gastos),
                          ),
                          _ActionIcon(
                            icon: Icons.travel_explore_rounded,
                            onTap: () =>
                                Navigator.pushNamed(context, RutasApp.chat),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
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
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  RutasApp.gastos,
                                ),
                                child: Text(
                                  'Gastos',
                                  style: AppTextStyles.boton(
                                    color: AppColors.blanco,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                onPressed: _mostrarDialogoAgregarMiembro,
                                child: Text(
                                  'Anadir miembro',
                                  style: AppTextStyles.boton(
                                    color: AppColors.coral,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

class _MiembroVista {
  const _MiembroVista({
    required this.id,
    required this.nombre,
    required this.color,
  });

  final String id;
  final String nombre;
  final Color color;
}

class _MiembroCard extends StatelessWidget {
  const _MiembroCard({required this.miembro});

  final _MiembroVista miembro;

  String _iniciales(String nombre) {
    final List<String> partes = nombre.trim().split(' ');
    if (partes.isEmpty || partes.first.isEmpty) return 'U';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes[0].substring(0, 1)}${partes[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 124,
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.verdeClaro, width: 4),
          ),
          child: Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[
                    miembro.color,
                    miembro.color.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  _iniciales(miembro.nombre),
                  style: AppTextStyles.h2(color: AppColors.blanco),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          miembro.nombre,
          style: AppTextStyles.boton(
            color: AppColors.negro,
          ).copyWith(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

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
        child: Icon(icon, size: 34, color: AppColors.blanco),
      ),
    );
  }
}
