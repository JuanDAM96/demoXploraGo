import 'package:flutter/material.dart';
import 'package:xplorago/controladores/chat_control.dart';
import 'package:xplorago/controladores/grupo_control.dart';
import 'package:xplorago/modelo/mensaje.dart';
import 'package:xplorago/nucleo/conexion/supabase_conexion_client.dart';
import 'package:xplorago/nucleo/navegacion/navegacion_app.dart';
import 'package:xplorago/nucleo/navegacion/rutas_app.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/widgets/bottom_bar.dart';

class PantallaChat extends StatefulWidget {
  const PantallaChat({super.key});

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final TextEditingController _mensajeController = TextEditingController();
  final ChatControl _chatControl = ChatControl();
  final GrupoControl _grupoControl = GrupoControl();

  String? _grupoIdActual;
  String? _usuarioIdActual;
  bool _inicializando = true;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _chatControl.dispose();
    _grupoControl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _inicializarChat() async {
    final String? usuarioId = SupabaseConexion.cliente.auth.currentUser?.id;
    _usuarioIdActual = usuarioId;

    if (usuarioId == null) {
      if (mounted) {
        setState(() {
          _inicializando = false;
        });
      }
      return;
    }

    try {
      await _grupoControl.cargarGrupos(usuarioId);
      if (_grupoControl.grupoActual == null && _grupoControl.grupos.isNotEmpty) {
        await _grupoControl.seleccionarGrupo(_grupoControl.grupos.first.id);
      }

      _grupoIdActual = _grupoControl.grupoActual?.id;
      if (_grupoIdActual != null) {
        await _chatControl.cargarMensajesPorGrupo(_grupoIdActual!);
      }
    } catch (e) {
      _mostrarMensaje('No se pudo cargar el chat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _inicializando = false;
        });
      }
    }
  }

  Future<void> _recargarMensajes() async {
    final String? grupoId = _grupoIdActual;
    if (grupoId == null) return;

    try {
      await _chatControl.cargarMensajesPorGrupo(grupoId);
      setState(() {});
    } catch (e) {
      _mostrarMensaje('No se pudo actualizar el chat: $e');
    }
  }

  Future<void> _enviarMensaje() async {
    final String texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    final String? grupoId = _grupoIdActual;
    final String? usuarioId = _usuarioIdActual;
    if (grupoId == null || usuarioId == null) {
      _mostrarMensaje('Necesitas un grupo activo para enviar mensajes.');
      return;
    }

    try {
      await _chatControl.enviarMensaje(
        grupoId: grupoId,
        usuarioId: usuarioId,
        texto: texto,
      );
      if (mounted) {
        _mensajeController.clear();
        setState(() {});
      }
    } catch (e) {
      _mostrarMensaje('No se pudo enviar el mensaje: $e');
    }
  }

  List<_MensajeUi> _mensajesUi() {
    return _chatControl.mensajes.map((Mensaje m) {
      final bool esMio = m.usuarioId == _usuarioIdActual;
      return _MensajeUi(
        autor: esMio ? 'Tú' : 'Miembro',
        texto: m.texto,
        esMio: esMio,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<_MensajeUi> mensajes = _mensajesUi();
    final bool cargando = _inicializando || _chatControl.cargando;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: topBarPrincipal(context),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: bottomBarPrincipal(
            context,
            itemActivo: BottomBarItem.grupo,
            rutaAtras: RutasApp.home,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: Column(
            children: [
              if (_grupoIdActual == null && !_inicializando)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No hay grupo activo para cargar el chat.',
                    style: AppTextStyles.texto(color: AppColors.coralFuerte),
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.verdeOscuro, width: 3),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.verdeOscuro,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Chat del grupo',
                          style: AppTextStyles.h2(
                            color: AppColors.blanco,
                          ).copyWith(fontSize: 36),
                        ),
                      ),
                      if (cargando)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: 0.2,
                                child: Image.asset(
                                  'assets/imagenes/splash.png',
                                  width: 180,
                                  height: 260,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            RefreshIndicator(
                              onRefresh: _recargarMensajes,
                              color: AppColors.coral,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                                itemCount: mensajes.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final _MensajeUi mensaje = mensajes[index];
                                  return _BurbujaMensaje(mensaje: mensaje);
                                },
                              ),
                            ),
                            if (mensajes.isEmpty && !cargando)
                              Center(
                                child: Text(
                                  'Aún no hay mensajes.',
                                  style: AppTextStyles.texto(
                                    color: AppColors.grisClaro,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        height: 50,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.verdeOscuro,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sentiment_satisfied_alt,
                              color: AppColors.verdeOscuro,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _mensajeController,
                                decoration: InputDecoration(
                                  hintText: 'Escribe un mensaje...',
                                  hintStyle: AppTextStyles.texto(
                                    color: AppColors.grisClaro,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: AppTextStyles.texto(color: AppColors.negro),
                                onSubmitted: (_) => _enviarMensaje(),
                              ),
                            ),
                            IconButton(
                              onPressed: cargando ? null : _enviarMensaje,
                              icon: const Icon(
                                Icons.send_rounded,
                                color: AppColors.verdeOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MensajeUi {
  const _MensajeUi({
    required this.autor,
    required this.texto,
    required this.esMio,
  });

  final String autor;
  final String texto;
  final bool esMio;
}

class _BurbujaMensaje extends StatelessWidget {
  const _BurbujaMensaje({required this.mensaje});

  final _MensajeUi mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: mensaje.esMio
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!mensaje.esMio)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                mensaje.autor,
                style: AppTextStyles.etiqueta(
                  color: AppColors.negro,
                ).copyWith(fontSize: 16),
              ),
            ),
          Container(
            constraints: const BoxConstraints(maxWidth: 230),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: mensaje.esMio
                  ? const Color(0xFFB6EA7C)
                  : const Color(0xFFEDE3B8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.verdeOscuro, width: 3),
            ),
            child: Text(
              mensaje.texto,
              style: AppTextStyles.texto(color: AppColors.negro),
            ),
          ),
        ],
      ),
    );
  }
}
