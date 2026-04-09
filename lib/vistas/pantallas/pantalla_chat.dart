import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/navegacion/RutasApp.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';
import 'package:xplorago/vistas/componentes/TopBar.dart';
import 'package:xplorago/vistas/widgets/BottomBar.dart';

class PantallaChat extends StatefulWidget {
  const PantallaChat({super.key});

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final TextEditingController _mensajeController = TextEditingController(
    text: 'Si, nos vemos!',
  );

  final List<_MensajeUi> _mensajes = <_MensajeUi>[
    const _MensajeUi(
      autor: 'Guadalupe',
      texto: 'A que hora salimos?',
      esMio: false,
    ),
    const _MensajeUi(
      autor: 'Tu',
      texto: 'Te parece bien a las 8:00?',
      esMio: true,
    ),
    const _MensajeUi(
      autor: 'Guadalupe',
      texto: 'Genial! Nos vemos en tu casa?',
      esMio: false,
    ),
  ];

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  void _enviarMensaje() {
    final String texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensajes.add(_MensajeUi(autor: 'Tu', texto: texto, esMio: true));
      _mensajeController.clear();
    });
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: Column(
            children: [
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
                          'Viaje Express',
                          style: AppTextStyles.h2(
                            color: AppColors.blanco,
                          ).copyWith(fontSize: 40 - 4),
                        ),
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
                            ListView.builder(
                              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                              itemCount: _mensajes.length,
                              itemBuilder: (BuildContext context, int index) {
                                final _MensajeUi mensaje = _mensajes[index];
                                return _BurbujaMensaje(mensaje: mensaje);
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                                style: AppTextStyles.texto(
                                  color: AppColors.negro,
                                ),
                                onSubmitted: (_) => _enviarMensaje(),
                              ),
                            ),
                            IconButton(
                              onPressed: _enviarMensaje,
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
              BottomBar(
                itemActivo: BottomBarItem.grupo,
                onAtras: () => Navigator.pushNamed(context, RutasApp.home),
                onGrupo: () => Navigator.pushNamed(context, RutasApp.grupo),
                onGastos: () => Navigator.pushNamed(context, RutasApp.gastos),
              ),
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
                ).copyWith(fontSize: 24 - 8),
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
