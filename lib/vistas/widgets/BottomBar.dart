import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';

enum BottomBarItem { atras, grupo, gastos, chat }

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    this.itemActivo,
    this.onAtras,
    this.onGrupo,
    this.onGastos,
    this.onChat,
    this.mostrarChat = false,
  });

  final BottomBarItem? itemActivo;
  final VoidCallback? onAtras;
  final VoidCallback? onGrupo;
  final VoidCallback? onGastos;
  final VoidCallback? onChat;
  final bool mostrarChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blanco.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomBarButton(
            assetPath: 'assets/iconos/iconoAtras.png',
            activo: itemActivo == BottomBarItem.atras,
            onTap: onAtras,
          ),
          _BottomBarButton(
            assetPath: 'assets/iconos/iconoGrupo.png',
            activo: itemActivo == BottomBarItem.grupo,
            onTap: onGrupo,
          ),
          _BottomBarButton(
            assetPath: 'assets/iconos/iconoGastos.png',
            activo: itemActivo == BottomBarItem.gastos,
            onTap: onGastos,
          ),
          if (mostrarChat)
            _BottomBarButton(
              assetPath: 'assets/iconos/iconoChat.png',
              activo: itemActivo == BottomBarItem.chat,
              onTap: onChat,
            ),
        ],
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton({
    required this.assetPath,
    required this.activo,
    this.onTap,
  });

  final String assetPath;
  final bool activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 46,
        decoration: BoxDecoration(
          color: activo
              ? AppColors.verdeClaro.withValues(alpha: 0.28)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
