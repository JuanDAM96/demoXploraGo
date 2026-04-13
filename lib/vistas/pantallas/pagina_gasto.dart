import 'package:flutter/material.dart';
import 'package:xplorago/controladores/gasto_control.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/modelo/gasto.dart';
import 'package:xplorago/modelo/usuario.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/servicios/usuario_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/texto_util.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/navegacion_app.dart';
import 'package:xplorago/vistas/widgets/bottom_bar.dart';

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

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _mostrarDialogoNuevoGasto() async {
    final String? grupoId = _grupoControl.grupoActual?.id;
    if (grupoId == null || _miembroIds.isEmpty) {
      _mostrarMensaje('Necesitas un grupo con miembros para crear gastos.');
      return;
    }

    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController montoController = TextEditingController();
    String pagadoPor = _miembroIds.first;
    final Set<String> participantes = <String>{..._miembroIds};
    bool repartoPersonalizado = false;
    final Map<String, TextEditingController> repartoControllers =
        <String, TextEditingController>{
          for (final String id in _miembroIds) id: TextEditingController(),
        };

    final bool? creado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext _,
                void Function(void Function()) setDialogState,
              ) {
            return AlertDialog(
              title: const Text('Nuevo gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej. Cena, gasolina...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto (€)',
                        hintText: '0.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: pagadoPor,
                      decoration: const InputDecoration(labelText: 'Pagado por'),
                      items: _miembroIds.map((String id) {
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
                    const SizedBox(height: 12),
                    Text(
                      'Participan en este gasto',
                      style: AppTextStyles.boton(color: AppColors.verdeOscuro),
                    ),
                    const SizedBox(height: 6),
                    ..._miembroIds.map((String id) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: participantes.contains(id),
                        title: Text(_nombreUsuario(id)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? checked) {
                          setDialogState(() {
                            if (checked == true) {
                              participantes.add(id);
                            } else {
                              participantes.remove(id);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reparto personalizado'),
                      subtitle: const Text(
                        'Actívalo si no queréis dividir a partes iguales.',
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
                              double.tryParse(
                                montoController.text.trim().replaceAll(',', '.'),
                              ) ??
                              0;
                          final int count = participantes.length;
                          final double porPersona =
                              count > 0 ? monto / count : 0;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              count > 0
                                  ? 'A partes iguales: ${_euros(porPersona)} por persona.'
                                  : 'Selecciona al menos un participante.',
                              style: AppTextStyles.texto(
                                color: AppColors.grisClaro,
                              ),
                            ),
                          );
                        },
                      ),
                    if (repartoPersonalizado)
                      ...participantes.map((String id) {
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
                    if (participantes.isEmpty) {
                      _mostrarMensaje('Selecciona al menos un participante.');
                      return;
                    }

                    Map<String, double>? reparto;
                    if (repartoPersonalizado) {
                      reparto = <String, double>{};
                      double suma = 0;
                      for (final String id in participantes) {
                        final String raw =
                            repartoControllers[id]?.text.trim() ?? '';
                        final double? valor = double.tryParse(
                          raw.replaceAll(',', '.'),
                        );
                        if (valor == null || valor <= 0) {
                          _mostrarMensaje(
                            'Importe inválido para ${_nombreUsuario(id)}.',
                          );
                          return;
                        }
                        reparto[id] = valor;
                        suma += valor;
                      }

                      if ((suma - monto).abs() > 0.01) {
                        _mostrarMensaje(
                          'La suma del reparto (${_euros(suma)}) debe ser igual al monto (${_euros(monto)}).',
                        );
                        return;
                      }
                    }

                    try {
                      await _gastoControl.crearGasto(
                        grupoId: grupoId,
                        descripcion: descripcion,
                        monto: monto,
                        pagadoPor: pagadoPor,
                        divididoEntre: participantes.toList(),
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

    // Evitamos dispose inmediato aquí para no chocar con el teardown interno
    // de los TextField/EditableText al cerrarse el diálogo en ciertos devices.

    if (creado == true && mounted) {
      _mostrarMensaje('Gasto añadido correctamente.');
    }
  }

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
      if (mounted) {
        setState(() {
          _cargandoUsuarios = false;
        });
      }
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
      balance[gasto.pagadoPor] = (balance[gasto.pagadoPor] ?? 0) + gasto.monto;

      if (gasto.reparto.isNotEmpty) {
        for (final MapEntry<String, double> entrada in gasto.reparto.entries) {
          balance[entrada.key] = (balance[entrada.key] ?? 0) - entrada.value;
        }
        continue;
      }

      final List<String> participantes = gasto.divididoEntre.isNotEmpty
          ? gasto.divididoEntre
          : _miembroIds;
      if (participantes.isEmpty) continue;

      final double cuota = gasto.monto / participantes.length;
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
                                      obtenerIniciales(nombre),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
