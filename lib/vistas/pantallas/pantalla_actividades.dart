import 'package:flutter/material.dart';
import 'package:xplorago/controladores/activdad_control.dart';
import 'package:xplorago/modelo/actividad.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:xplorago/nucleo/navegacion/navegacion_app.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';

class PantallaActividades extends StatefulWidget {
  const PantallaActividades({super.key});

  @override
  State<PantallaActividades> createState() => _PantallaActividadesState();
}

class _PantallaActividadesState extends State<PantallaActividades> {
  final ActividadControl _actividadControl = ActividadControl();

  String? _grupoId;
  String? _usuarioId;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;

    final dynamic arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && arg.trim().isNotEmpty) {
      _grupoId = arg.trim();
    }

    _usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _actividadControl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    if (_grupoId == null || _usuarioId == null) return;
    try {
      await _actividadControl.cargarActividadesPorGrupo(_grupoId!);
      await _actividadControl.cargarAsistenciaUsuario(_usuarioId!);
      await _actividadControl.cargarApuntadosDeTodasLasActividades();
    } catch (_) {
      // El error se muestra desde _actividadControl.error.
    }
  }

  Future<void> _alternarAsistencia(Actividad actividad) async {
    if (_usuarioId == null) return;
    try {
      await _actividadControl.alternarAsistenciaUsuario(
        actividadId: actividad.id,
        usuarioId: _usuarioId!,
      );
      await _actividadControl.refrescarApuntadosDeActividad(actividad.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  Future<void> _mostrarDialogoCrearActividad() async {
    if (_grupoId == null) return;

    final TextEditingController tituloController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuevo plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Titulo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripcion'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || tituloController.text.trim().isEmpty) {
      tituloController.dispose();
      descripcionController.dispose();
      return;
    }

    try {
      await _actividadControl.crearActividad(
        grupoId: _grupoId!,
        titulo: tituloController.text.trim(),
        descripcion: descripcionController.text.trim().isEmpty
            ? null
            : descripcionController.text.trim(),
        creadoPor: _usuarioId,
      );
      if (_usuarioId != null) {
        await _actividadControl.cargarAsistenciaUsuario(_usuarioId!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo crear el plan: $e')));
    } finally {
      tituloController.dispose();
      descripcionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: topBarPrincipal(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearActividad,
        backgroundColor: AppColors.verdeOscuro,
        foregroundColor: AppColors.blanco,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo plan'),
      ),
      body: AnimatedBuilder(
        animation: _actividadControl,
        builder: (BuildContext context, Widget? child) {
          if (_grupoId == null) {
            return Center(
              child: Text(
                'No se recibió grupo para cargar planes.',
                style: AppTextStyles.texto(color: AppColors.coral),
              ),
            );
          }

          if (_actividadControl.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_actividadControl.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _actividadControl.error!,
                  style: AppTextStyles.texto(color: AppColors.coral),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (_actividadControl.actividades.isEmpty) {
            return Center(
              child: Text(
                'Aun no hay planes. Crea el primero.',
                style: AppTextStyles.texto(color: AppColors.negro),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _cargarDatosIniciales,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              itemBuilder: (BuildContext context, int index) {
                final Actividad actividad = _actividadControl.actividades[index];
                final bool apuntado = _actividadControl.estaApuntadoEn(
                  actividad.id,
                );
                final List<String> apuntados = _actividadControl
                    .obtenerNombresApuntados(actividad.id);

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    isThreeLine: true,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            actividad.titulo,
                            style: AppTextStyles.boton(color: AppColors.negro),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verdeClaro.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${apuntados.length} apuntados',
                            style: AppTextStyles.microEtiqueta(
                              color: AppColors.verdeOscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad.descripcion ?? 'Sin descripcion',
                          style: AppTextStyles.texto(
                            color: AppColors.grisClaro,
                          ).copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        if (apuntados.isEmpty)
                          Text(
                            'Nadie se ha apuntado aun',
                            style: AppTextStyles.texto(
                              color: AppColors.grisClaro,
                            ).copyWith(fontSize: 12),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: apuntados
                                .map(
                                  (String nombre) => Chip(
                                    backgroundColor: AppColors.verdeClaro
                                        .withValues(alpha: 0.20),
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      nombre,
                                      style: AppTextStyles.microEtiqueta(
                                        color: AppColors.verdeOscuro,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => _alternarAsistencia(actividad),
                      icon: Icon(
                        apuntado ? Icons.check_circle : Icons.add_circle_outline,
                        color: apuntado
                            ? AppColors.verdeOscuro
                            : AppColors.grisClaro,
                      ),
                      label: Text(apuntado ? 'Apuntado' : 'Apuntarme'),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, int index) => const SizedBox(height: 8),
              itemCount: _actividadControl.actividades.length,
            ),
          );
        },
      ),
    );
  }
}
