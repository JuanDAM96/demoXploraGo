import 'package:flutter/material.dart';
import 'package:xplorago/controladores/activdad_control.dart';
import 'package:xplorago/controladores/gasto_control.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/modelo/actividad.dart';
import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/modelo/grupo.dart';
import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:xplorago/nucleo/navegacion/navegacion_app.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/widgets/bottom_bar.dart';

class PantallaGasto extends StatefulWidget {
  const PantallaGasto({super.key});

  @override
  State<PantallaGasto> createState() => _PantallaGastoState();
}

class _PantallaGastoState extends State<PantallaGasto> {
  final GrupoControl _grupoControl = GrupoControl();
  final ActividadControl _actividadControl = ActividadControl();
  final GastoControl _gastoControl = GastoControl();
  final UsuarioServicio _usuarioServicio = UsuarioServicio();

  final Map<String, Usuario> _usuarios = <String, Usuario>{};

  String? _usuarioId;
  String? _grupoIdSeleccionado;
  String? _actividadIdSeleccionada;
  String? _rolUsuarioActual;

  double _totalGrupo = 0;
  double _totalActividad = 0;
  bool _cargandoVista = false;

  bool get _esAdmin => _rolUsuarioActual == 'admin';

  Actividad? get _actividadActual {
    if (_actividadIdSeleccionada == null) return null;
    for (final Actividad actividad in _actividadControl.actividades) {
      if (actividad.id == _actividadIdSeleccionada) return actividad;
    }
    return null;
  }

  List<String> get _apuntadosActividadActual {
    if (_actividadIdSeleccionada == null) return <String>[];
    return _actividadControl.obtenerIdsApuntados(_actividadIdSeleccionada!);
  }

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  @override
  void dispose() {
    _grupoControl.dispose();
    _actividadControl.dispose();
    _gastoControl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _cargarInicial() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    if (usuarioId == null) return;

    setState(() {
      _usuarioId = usuarioId;
      _cargandoVista = true;
    });

    try {
      await _grupoControl.cargarGrupos(usuarioId);
      if (_grupoControl.grupos.isEmpty) return;

      final String grupoInicial =
          _grupoControl.grupoActual?.id ?? _grupoControl.grupos.first.id;
      await _cambiarGrupo(grupoInicial);
    } finally {
      if (mounted) {
        setState(() {
          _cargandoVista = false;
        });
      }
    }
  }

  Future<void> _cambiarGrupo(String grupoId) async {
    if (_usuarioId == null) return;

    setState(() {
      _grupoIdSeleccionado = grupoId;
      _actividadIdSeleccionada = null;
      _rolUsuarioActual = null;
      _totalActividad = 0;
      _totalGrupo = 0;
    });

    await _grupoControl.seleccionarGrupo(grupoId);
    _rolUsuarioActual =
        await _grupoControl.obtenerRolMiembro(grupoId, _usuarioId!);

    await _actividadControl.cargarActividadesPorGrupo(grupoId);
    await _actividadControl.cargarAsistenciaUsuario(_usuarioId!);
    await _actividadControl.cargarApuntadosDeTodasLasActividades();

    final List<Actividad> actividades = _actividadControl.actividades;
    if (actividades.isNotEmpty) {
      final Actividad actividadInicial = actividades.firstWhere(
        (Actividad a) => !a.completada,
        orElse: () => actividades.first,
      );
      await _cambiarActividad(actividadInicial.id);
    } else {
      await _gastoControl.cargarGastosPorGrupo(grupoId);
      _totalGrupo = await _gastoControl.obtenerTotalPorGrupo(grupoId);
    }

    if (mounted) setState(() {});
  }

  Future<void> _cambiarActividad(String actividadId) async {
    final String? grupoId = _grupoIdSeleccionado;
    if (grupoId == null) return;

    setState(() {
      _actividadIdSeleccionada = actividadId;
      _cargandoVista = true;
    });

    try {
      await _actividadControl.refrescarApuntadosDeActividad(actividadId);
      await _gastoControl.cargarGastosPorGrupoYActividad(
        grupoId: grupoId,
        actividadId: actividadId,
      );
      await _cargarUsuariosRelacionados(actividadId);

      _totalGrupo = await _gastoControl.obtenerTotalPorGrupo(grupoId);
      _totalActividad = await _gastoControl.obtenerTotalPorActividad(
        grupoId: grupoId,
        actividadId: actividadId,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargandoVista = false;
        });
      }
    }
  }

  Future<void> _cargarUsuariosRelacionados(String actividadId) async {
    final Set<String> ids = <String>{
      ..._actividadControl.obtenerIdsApuntados(actividadId),
    };

    for (final Gasto gasto in _gastoControl.gastos) {
      ids.add(gasto.pagadoPor);
      ids.addAll(gasto.divididoEntre);
      ids.addAll(gasto.reparto.keys);
    }

    for (final String id in ids) {
      if (_usuarios.containsKey(id)) continue;
      try {
        _usuarios[id] = await _usuarioServicio.obtenerPorId(id);
      } catch (_) {}
    }
  }

  String _nombreUsuario(String usuarioId) {
    final Usuario? usuario = _usuarios[usuarioId];
    if (usuario == null) {
      return usuarioId.substring(0, usuarioId.length >= 8 ? 8 : usuarioId.length);
    }

    if (usuario.nombreUsuario?.trim().isNotEmpty == true) {
      return usuario.nombreUsuario!.trim();
    }
    if (usuario.nombre?.trim().isNotEmpty == true) {
      return usuario.nombre!.trim();
    }
    if (usuario.correo?.trim().isNotEmpty == true) {
      return usuario.correo!.split('@').first;
    }
    return usuarioId.substring(0, usuarioId.length >= 8 ? 8 : usuarioId.length);
  }

  String _euros(double valor) {
    final String texto = valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2);
    return '$texto€';
  }

  String _resumenDeudasActividad() {
    final List<String> miembros = _apuntadosActividadActual;
    if (_gastoControl.gastos.isEmpty || miembros.isEmpty) {
      return 'Aun no hay deudas calculadas para esta actividad.';
    }

    final Map<String, double> balance = <String, double>{
      for (final String id in miembros) id: 0,
    };

    for (final Gasto gasto in _gastoControl.gastos) {
      balance[gasto.pagadoPor] = (balance[gasto.pagadoPor] ?? 0) + gasto.monto;

      if (gasto.reparto.isNotEmpty) {
        for (final MapEntry<String, double> entrada in gasto.reparto.entries) {
          balance[entrada.key] = (balance[entrada.key] ?? 0) - entrada.value;
        }
      } else {
        final List<String> participantes =
            gasto.divididoEntre.isNotEmpty ? gasto.divididoEntre : miembros;
        if (participantes.isEmpty) continue;
        final double cuota = gasto.monto / participantes.length;
        for (final String participante in participantes) {
          balance[participante] = (balance[participante] ?? 0) - cuota;
        }
      }
    }

    final List<MapEntry<String, double>> acreedores = balance.entries
        .where((MapEntry<String, double> e) => e.value > 0.01)
        .toList();
    final List<MapEntry<String, double>> deudores = balance.entries
        .where((MapEntry<String, double> e) => e.value < -0.01)
        .toList();

    if (acreedores.isEmpty || deudores.isEmpty) {
      return 'Cuentas equilibradas en esta actividad.';
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

  Future<void> _cerrarActividad() async {
    final Actividad? actividad = _actividadActual;
    if (actividad == null || actividad.completada) return;

    if (!_esAdmin) {
      _mostrarMensaje('Solo el admin puede cerrar/saldar la actividad.');
      return;
    }

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar actividad'),
          content: const Text(
            '¿Quieres cerrar esta actividad? Los gastos quedarán visibles, pero ya no podrán modificarse.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar y saldar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _actividadControl.marcarCompletada(actividad.id);
      await _cambiarGrupo(_grupoIdSeleccionado!);
      _mostrarMensaje('Actividad cerrada correctamente.');
    } catch (e) {
      _mostrarMensaje('No se pudo cerrar la actividad: $e');
    }
  }

  Future<void> _mostrarDialogoNuevoGasto() async {
    final String? grupoId = _grupoIdSeleccionado;
    final String? actividadId = _actividadIdSeleccionada;
    final Actividad? actividad = _actividadActual;

    if (grupoId == null || actividadId == null || actividad == null) {
      _mostrarMensaje('Selecciona grupo y actividad para añadir gasto.');
      return;
    }

    if (actividad.completada) {
      _mostrarMensaje('La actividad está cerrada y no admite nuevos gastos.');
      return;
    }

    final List<String> apuntados =
        _actividadControl.obtenerIdsApuntados(actividadId);
    if (apuntados.isEmpty) {
      _mostrarMensaje('No hay apuntados en esta actividad.');
      return;
    }

    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController montoController = TextEditingController();
    final Map<String, TextEditingController> repartoControllers =
        <String, TextEditingController>{
      for (final String id in apuntados) id: TextEditingController(),
    };

    String pagadoPor = apuntados.first;
    bool repartoPersonalizado = false;

    final bool? creado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext _,
            void Function(void Function()) setDialogState,
          ) {
            return AlertDialog(
              title: const Text('Nuevo gasto de actividad'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actividad.titulo,
                      style: AppTextStyles.boton(color: AppColors.verdeOscuro),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej. cena, gasolina, entradas...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto (€)',
                        hintText: '0.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: pagadoPor,
                      decoration: const InputDecoration(labelText: 'Pagado por'),
                      items: apuntados.map((String id) {
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(_nombreUsuario(id)),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value == null) return;
                        setDialogState(() {
                          pagadoPor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reparto personalizado'),
                      subtitle: const Text(
                        'Permite que algunas personas paguen distinto o incluso 0€.',
                      ),
                      value: repartoPersonalizado,
                      onChanged: (bool value) {
                        setDialogState(() {
                          repartoPersonalizado = value;
                        });
                      },
                    ),
                    if (!repartoPersonalizado)
                      Builder(
                        builder: (_) {
                          final double monto =
                              double.tryParse(montoController.text.trim().replaceAll(',', '.')) ??
                                  0;
                          final double porPersona = apuntados.isNotEmpty
                              ? monto / apuntados.length
                              : 0;
                          return Text(
                            'Se reparte entre ${apuntados.length} apuntados: ${_euros(porPersona)} por persona.',
                            style: AppTextStyles.texto(color: AppColors.grisClaro),
                          );
                        },
                      ),
                    if (repartoPersonalizado)
                      ...apuntados.map((String id) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: repartoControllers[id],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: '${_nombreUsuario(id)} paga',
                              hintText: '0.00',
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String descripcion = descripcionController.text.trim();
                    final double? monto = double.tryParse(
                      montoController.text.trim().replaceAll(',', '.'),
                    );

                    if (descripcion.isEmpty || monto == null || monto <= 0) {
                      _mostrarMensaje('Introduce descripción y un monto válido.');
                      return;
                    }

                    Map<String, double>? reparto;
                    if (repartoPersonalizado) {
                      reparto = <String, double>{};
                      double suma = 0;
                      for (final String id in apuntados) {
                        final String raw = repartoControllers[id]?.text.trim() ?? '';
                        final double valor = raw.isEmpty
                            ? 0
                            : (double.tryParse(raw.replaceAll(',', '.')) ?? -1);

                        if (valor < 0) {
                          _mostrarMensaje('Importe inválido para ${_nombreUsuario(id)}.');
                          return;
                        }

                        reparto[id] = valor;
                        suma += valor;
                      }

                      if ((suma - monto).abs() > 0.01) {
                        _mostrarMensaje(
                          'La suma personalizada (${_euros(suma)}) debe ser igual al monto (${_euros(monto)}).',
                        );
                        return;
                      }
                    }

                    try {
                      await _gastoControl.crearGasto(
                        grupoId: grupoId,
                        actividadId: actividadId,
                        descripcion: descripcion,
                        monto: monto,
                        pagadoPor: pagadoPor,
                        divididoEntre: apuntados,
                        reparto: reparto,
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      _mostrarMensaje('No se pudo crear el gasto: $e');
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (creado == true && mounted && _actividadIdSeleccionada != null) {
      await _cambiarActividad(_actividadIdSeleccionada!);
      _mostrarMensaje('Gasto añadido correctamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Grupo> grupos = _grupoControl.grupos;
    final List<Actividad> actividades = _actividadControl.actividades;
    final Actividad? actividad = _actividadActual;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: topBarPrincipal(context),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: bottomBarPrincipal(
            context,
            itemActivo: BottomBarItem.gastos,
            rutaAtras: RutasApp.home,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoGasto,
        backgroundColor: AppColors.verdeOscuro,
        foregroundColor: AppColors.blanco,
        icon: const Icon(Icons.add),
        label: const Text('Añadir gasto'),
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
              onRefresh: _cargarInicial,
              color: AppColors.coral,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  if (_cargandoVista ||
                      _grupoControl.cargando ||
                      _actividadControl.cargando ||
                      _gastoControl.cargando)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 4),
                    ),
                  Text(
                    'Gastos por actividad',
                    style: AppTextStyles.h2(color: AppColors.verdeOscuro),
                  ),
                  const SizedBox(height: 10),
                  if (grupos.isEmpty)
                    Text(
                      'No tienes grupos disponibles.',
                      style: AppTextStyles.texto(color: AppColors.grisClaro),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _grupoIdSeleccionado ?? grupos.first.id,
                      decoration: const InputDecoration(labelText: 'Grupo'),
                      items: grupos
                          .map(
                            (Grupo grupo) => DropdownMenuItem<String>(
                              value: grupo.id,
                              child: Text(grupo.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value == null) return;
                        _cambiarGrupo(value);
                      },
                    ),
                  const SizedBox(height: 10),
                  if (actividades.isEmpty)
                    Text(
                      'Este grupo aún no tiene actividades.',
                      style: AppTextStyles.texto(color: AppColors.grisClaro),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _actividadIdSeleccionada ?? actividades.first.id,
                      decoration: const InputDecoration(labelText: 'Actividad'),
                      items: actividades.map((Actividad a) {
                        final String estado = a.completada ? 'Cerrada' : 'Abierta';
                        return DropdownMenuItem<String>(
                          value: a.id,
                          child: Text('${a.titulo} · $estado'),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value == null) return;
                        _cambiarActividad(value);
                      },
                    ),
                  const SizedBox(height: 12),
                  if (actividad != null)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: actividad.completada
                                  ? AppColors.coral.withValues(alpha: 0.15)
                                  : AppColors.verdeClaro.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              actividad.completada
                                  ? 'Actividad cerrada: solo lectura'
                                  : 'Actividad abierta: edición permitida',
                              style: AppTextStyles.microEtiqueta(
                                color: actividad.completada
                                    ? AppColors.coralFuerte
                                    : AppColors.verdeOscuro,
                              ),
                            ),
                          ),
                        ),
                        if (_esAdmin && !actividad.completada) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _cerrarActividad,
                            child: const Text('Cerrar/saldar'),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Total actividad: ${_euros(_totalActividad)}',
                    style: AppTextStyles.boton(color: AppColors.negro),
                  ),
                  Text(
                    'Total grupo: ${_euros(_totalGrupo)}',
                    style: AppTextStyles.boton(color: AppColors.negro),
                  ),
                  const SizedBox(height: 16),
                  if (_gastoControl.gastos.isEmpty)
                    Text(
                      'No hay gastos en esta actividad.',
                      style: AppTextStyles.texto(color: AppColors.grisClaro),
                    )
                  else
                    ..._gastoControl.gastos.map((Gasto gasto) {
                      final List<String> participantes = gasto.reparto.isNotEmpty
                          ? gasto.reparto.keys.map(_nombreUsuario).toList()
                          : gasto.divididoEntre.map(_nombreUsuario).toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            '${gasto.descripcion} · ${_euros(gasto.monto)}',
                            style: AppTextStyles.boton(color: AppColors.negro),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pagó: ${_nombreUsuario(gasto.pagadoPor)}',
                                style: AppTextStyles.texto(
                                  color: AppColors.grisClaro,
                                ).copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Participan: ${participantes.join(', ')}',
                                style: AppTextStyles.texto(
                                  color: AppColors.grisClaro,
                                ).copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  Text(
                    'Resumen de saldos',
                    style: AppTextStyles.h2(color: AppColors.verdeOscuro)
                        .copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resumenDeudasActividad(),
                    style: AppTextStyles.texto(color: AppColors.negro),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
