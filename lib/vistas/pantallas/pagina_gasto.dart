import 'package:flutter/material.dart';
import 'package:xplorago/controladores/gasto_control.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/TopBar.dart';
import 'package:xplorago/vistas/widgets/BottomBar.dart';

class PaginaGasto extends StatefulWidget {
  const PaginaGasto({super.key});

  @override
  State<PaginaGasto> createState() => _PaginaGastoState();
}

class _PaginaGastoState extends State<PaginaGasto> {
  final GrupoControl _grupoControl = GrupoControl();
  final GastoControl _gastoControl = GastoControl();
  final UsuarioServicio _usuarioServicio = UsuarioServicio();

  final Map<String, Usuario> _usuarios = <String, Usuario>{};
  List<String> _miembroIds = <String>[];
  bool _cargandoUsuarios = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _grupoControl.dispose();
    _gastoControl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    if (usuarioId == null) return;

    await _grupoControl.cargarGrupos(usuarioId);
    if (_grupoControl.grupoActual == null && _grupoControl.grupos.isNotEmpty) {
      await _grupoControl.seleccionarGrupo(_grupoControl.grupos.first.id);
    }

    final String? grupoId = _grupoControl.grupoActual?.id;
    if (grupoId == null) return;

    await _gastoControl.cargarGastosPorGrupo(grupoId);
    await _cargarUsuariosDelGrupo(grupoId, usuarioId);
  }

  Future<void> _cargarUsuariosDelGrupo(
    String grupoId,
    String usuarioIdActual,
  ) async {
    if (!mounted) return;
    setState(() {
      _cargandoUsuarios = true;
    });

    try {
      final List<String> ids = await _grupoControl.obtenerMiembroIds(grupoId);
      final Set<String> idsUnicos = <String>{...ids, usuarioIdActual};
      final String? creadorId = _grupoControl.grupoActual?.creadorId;
      if (creadorId != null && creadorId.isNotEmpty) {
        idsUnicos.add(creadorId);
      }

      final Map<String, Usuario> cargados = <String, Usuario>{};
      for (final String id in idsUnicos) {
        try {
          final Usuario usuario = await _usuarioServicio.obtenerPorId(id);
          cargados[id] = usuario;
        } catch (_) {
          // Si un perfil no existe, se omite y se mantiene el resto.
        }
      }

      if (!mounted) return;
      setState(() {
        _miembroIds = idsUnicos.toList();
        _usuarios
          ..clear()
          ..addAll(cargados);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _cargandoUsuarios = false;
      });
    }
  }

  String _nombreUsuario(String usuarioId) {
    final Usuario? usuario = _usuarios[usuarioId];
    if (usuario == null) return 'Usuario';

    if (usuario.nombreUsuario != null &&
        usuario.nombreUsuario!.trim().isNotEmpty) {
      return usuario.nombreUsuario!.trim();
    }
    if (usuario.nombre != null && usuario.nombre!.trim().isNotEmpty) {
      return usuario.nombre!.trim();
    }
    return 'Usuario';
  }

  String _iniciales(String nombre) {
    final List<String> partes = nombre.trim().split(' ');
    if (partes.isEmpty || partes.first.isEmpty) return 'U';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes[0].substring(0, 1)}${partes[1].substring(0, 1)}'
        .toUpperCase();
  }

  String _euros(double valor) {
    final String texto = valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2);
    return '$texto€';
  }

  List<Gasto> _gastosDe(String usuarioId) {
    return _gastoControl.gastos.where((g) => g.pagadoPor == usuarioId).toList();
  }

  double _totalDe(String usuarioId) {
    return _gastosDe(usuarioId).fold(0, (suma, g) => suma + g.monto);
  }

  String _resumenDeudas() {
    if (_gastoControl.gastos.isEmpty || _miembroIds.isEmpty) {
      return 'Aun no hay deudas calculadas.';
    }

    final Map<String, double> balance = <String, double>{
      for (final String id in _miembroIds) id: 0,
    };

    for (final Gasto gasto in _gastoControl.gastos) {
      final List<String> participantes = gasto.divididoEntre.isNotEmpty
          ? gasto.divididoEntre
          : _miembroIds;
      if (participantes.isEmpty) continue;

      final double cuota = gasto.monto / participantes.length;
      balance[gasto.pagadoPor] = (balance[gasto.pagadoPor] ?? 0) + gasto.monto;

      for (final String participante in participantes) {
        balance[participante] = (balance[participante] ?? 0) - cuota;
      }
    }

    final List<MapEntry<String, double>> acreedores = balance.entries
        .where((e) => e.value > 0.01)
        .toList();
    final List<MapEntry<String, double>> deudores = balance.entries
        .where((e) => e.value < -0.01)
        .toList();

    if (acreedores.isEmpty || deudores.isEmpty) {
      return 'Cuentas equilibradas.';
    }

    final List<String> lineas = <String>[];
    int i = 0;
    int j = 0;

    while (i < deudores.length && j < acreedores.length) {
      double deuda = -deudores[i].value;
      double credito = acreedores[j].value;
      final double pago = deuda < credito ? deuda : credito;

      lineas.add(
        '${_nombreUsuario(deudores[i].key)} debe ${_euros(pago)} a ${_nombreUsuario(acreedores[j].key)}',
      );

      deuda -= pago;
      credito -= pago;

      deudores[i] = MapEntry<String, double>(deudores[i].key, -deuda);
      acreedores[j] = MapEntry<String, double>(acreedores[j].key, credito);

      if (deuda <= 0.01) i++;
      if (credito <= 0.01) j++;
    }

    return lineas.join('\n');
  }

  List<String> _miembrosOrdenados() {
    final List<String> ids = _miembroIds
        .where((id) => _usuarios.containsKey(id))
        .toList();
    ids.sort(
      (a, b) => _nombreUsuario(
        a,
      ).toLowerCase().compareTo(_nombreUsuario(b).toLowerCase()),
    );
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> miembros = _miembrosOrdenados();
    final bool cargando =
        _grupoControl.cargando || _gastoControl.cargando || _cargandoUsuarios;

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
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.1, 0.05),
            child: Opacity(
              opacity: 0.14,
              child: Image.asset(
                'assets/imagenes/fondo.png',
                width: 320,
                height: 320,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _cargarDatos,
              color: AppColors.coral,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  if (cargando)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 4),
                    ),
                  if (miembros.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No hay gastos disponibles todavia.',
                        style: AppTextStyles.texto(color: AppColors.grisClaro),
                      ),
                    )
                  else
                    ...miembros.map((id) {
                      final List<Gasto> gastos = _gastosDe(id);
                      final String nombre = _nombreUsuario(id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.blanco,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.verdeOscuro,
                                      width: 4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _iniciales(nombre),
                                      style: AppTextStyles.h2(
                                        color: AppColors.verdeOscuro,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Gastos $nombre',
                                    style: AppTextStyles.h2(
                                      color: AppColors.verdeOscuro,
                                    ).copyWith(fontSize: 34 - 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (gastos.isEmpty)
                              Text(
                                'Sin gastos registrados',
                                style: AppTextStyles.texto(
                                  color: AppColors.grisClaro,
                                ),
                              )
                            else
                              ...gastos.map((gasto) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${gasto.descripcion} ${_euros(gasto.monto)}',
                                    style: AppTextStyles.texto(
                                      color: AppColors.negro,
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ${_euros(_totalDe(id))}',
                              style: AppTextStyles.boton(
                                color: AppColors.negro,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 14),
                  Text(
                    'Gastos Finales',
                    style: AppTextStyles.h2(color: AppColors.verdeOscuro),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _resumenDeudas(),
                    style: AppTextStyles.boton(color: AppColors.negro),
                  ),
                  const SizedBox(height: 96),
                  BottomBar(
                    itemActivo: BottomBarItem.gastos,
                    onAtras: () => Navigator.pushNamed(context, RutasApp.home),
                    onGrupo: () => Navigator.pushNamed(context, RutasApp.grupo),
                    onGastos: () =>
                        Navigator.pushNamed(context, RutasApp.gastos),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
