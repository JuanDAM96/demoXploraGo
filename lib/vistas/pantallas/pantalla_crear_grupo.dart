import 'package:flutter/material.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/nucleo/conexion/Supabase_conexion.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/TopBar.dart';
import 'package:xplorago/vistas/widgets/BottomBar.dart';

class PantallaCrearGrupo extends StatefulWidget {
  const PantallaCrearGrupo({super.key});

  @override
  State<PantallaCrearGrupo> createState() => _PantallaCrearGrupoState();
}

class _PantallaCrearGrupoState extends State<PantallaCrearGrupo> {
  final GrupoControl _grupoControl = GrupoControl();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _fechaSalidaController = TextEditingController();
  final TextEditingController _fechaLlegadaController = TextEditingController();
  final TextEditingController _miembroController = TextEditingController();

  final List<String> _miembros = <String>[];

  @override
  void initState() {
    super.initState();
    final String? nombreActual = SupabaseConexion
        .cliente
        .auth
        .currentUser
        ?.userMetadata?['nombre_usuario']
        ?.toString();

    _miembros.add(
      (nombreActual != null && nombreActual.trim().isNotEmpty)
          ? nombreActual.trim()
          : 'Guadalupe',
    );
  }

  @override
  void dispose() {
    _grupoControl.dispose();
    _nombreController.dispose();
    _destinoController.dispose();
    _fechaSalidaController.dispose();
    _fechaLlegadaController.dispose();
    _miembroController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final DateTime hoy = DateTime.now();
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;

    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    final String anio = fecha.year.toString();
    controller.text = '$dia/$mes/$anio';
  }

  void _agregarMiembro() {
    final String nombre = _miembroController.text.trim();
    if (nombre.isEmpty) return;

    if (_miembros.any((String m) => m.toLowerCase() == nombre.toLowerCase())) {
      _miembroController.clear();
      return;
    }

    setState(() {
      _miembros.add(nombre);
      _miembroController.clear();
    });
  }

  Future<void> _crearGrupo() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Usuario no autenticado. Por favor inicia sesión.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final String nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el nombre del grupo')),
      );
      return;
    }

    final String destino = _destinoController.text.trim();
    final String salida = _fechaSalidaController.text.trim();
    final String llegada = _fechaLlegadaController.text.trim();

    final String descripcion =
        'Salida: ${salida.isEmpty ? 'sin fecha' : salida} | Llegada: ${llegada.isEmpty ? 'sin fecha' : llegada} | Miembros: ${_miembros.join(', ')}';

    try {
      await _grupoControl.crearGrupo(
        nombre: nombre,
        destino: destino.isEmpty ? null : destino,
        descripcion: descripcion,
        creadorId: usuarioId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo creado correctamente')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        RutasApp.home,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo crear el grupo: $e')));
    }
  }

  String _iniciales(String nombre) {
    final List<String> partes = nombre.trim().split(' ');
    if (partes.isEmpty || partes.first.isEmpty) return 'U';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes[0].substring(0, 1)}${partes[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String miembroPrincipal = _miembros.isNotEmpty
        ? _miembros.first
        : 'Guadalupe';

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
            alignment: const Alignment(0, 0.02),
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/imagenes/fondo.png',
                width: 280,
                height: 280,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.negro.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        color: AppColors.negro,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Crear Grupo',
                      style: AppTextStyles.h2(
                        color: AppColors.negro,
                      ).copyWith(fontSize: 39 - 2),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FieldLabel(text: 'Nombre del Grupo'),
                const SizedBox(height: 4),
                _TextFieldBox(
                  controller: _nombreController,
                  hintText: 'Nombre Grupo',
                ),
                const SizedBox(height: 9),
                _FieldLabel(text: 'Destino'),
                const SizedBox(height: 4),
                _TextFieldBox(
                  controller: _destinoController,
                  hintText: 'Destino',
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(text: 'Fecha salida:'),
                          const SizedBox(height: 4),
                          _DateFieldBox(
                            controller: _fechaSalidaController,
                            hintText: '00/00/0000',
                            onTap: () =>
                                _seleccionarFecha(_fechaSalidaController),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(text: 'Fecha llegada:'),
                          const SizedBox(height: 4),
                          _DateFieldBox(
                            controller: _fechaLlegadaController,
                            hintText: '00/00/0000',
                            onTap: () =>
                                _seleccionarFecha(_fechaLlegadaController),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _FieldLabel(text: 'Miembros del Grupo'),
                const SizedBox(height: 4),
                Container(
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.negro.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _miembroController,
                          decoration: const InputDecoration(
                            hintText: 'Añadir contactos',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _agregarMiembro,
                        icon: const Icon(Icons.add, color: AppColors.negro),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.verdeOscuro,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _iniciales(miembroPrincipal),
                          style: AppTextStyles.boton(
                            color: AppColors.verdeOscuro,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        miembroPrincipal,
                        style: AppTextStyles.texto(
                          color: AppColors.negro,
                        ).copyWith(fontSize: 27 - 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_grupoControl.cargando)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
                const SizedBox(height: 74),
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.coral,
                          width: 4,
                        ),
                        foregroundColor: AppColors.coral,
                      ),
                      onPressed: _crearGrupo,
                      child: Text(
                        'Crear Grupo',
                        style: AppTextStyles.boton(color: AppColors.coral),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                BottomBar(
                  itemActivo: BottomBarItem.grupo,
                  onAtras: () => Navigator.pushNamed(context, RutasApp.home),
                  onGrupo: () => Navigator.pushNamed(context, RutasApp.grupo),
                  onGastos: () => Navigator.pushNamed(context, RutasApp.gastos),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.etiqueta(
        color: AppColors.negro,
      ).copyWith(fontSize: 13),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _DateFieldBox extends StatelessWidget {
  const _DateFieldBox({
    required this.controller,
    required this.hintText,
    required this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
