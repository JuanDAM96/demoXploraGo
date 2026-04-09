import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/servicios/auth_servicio.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';

class PantallaCambiarContrasena extends StatefulWidget {
  const PantallaCambiarContrasena({super.key});

  @override
  State<PantallaCambiarContrasena> createState() => _PantallaCambiarContrasenaState();
}

class _PantallaCambiarContrasenaState extends State<PantallaCambiarContrasena> {
  final TextEditingController _nuevaContrasenaController = TextEditingController();
  final TextEditingController _repiteContrasenaController = TextEditingController();
  final AuthServicio _authServicio = AuthServicio();

  bool _guardando = false;

  @override
  void dispose() {
    _nuevaContrasenaController.dispose();
    _repiteContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambio() async {
    final String nueva = _nuevaContrasenaController.text.trim();
    final String repite = _repiteContrasenaController.text.trim();

    if (nueva.isEmpty || repite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa ambos campos de contrasena.')),
      );
      return;
    }

    if (nueva.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contrasena debe tener al menos 6 caracteres.')),
      );
      return;
    }

    if (nueva != repite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contrasenas no coinciden.')),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _authServicio.cambiarContrasena(nuevaContrasena: nueva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrasena actualizada correctamente.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar la contrasena: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contrasena'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nuevaContrasenaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contrasena',
                labelStyle: AppTextStyles.etiqueta(color: AppColors.grisClaro),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _repiteContrasenaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Repite la contrasena',
                labelStyle: AppTextStyles.etiqueta(color: AppColors.grisClaro),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: _guardando ? null : _guardarCambio,
                child: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blanco),
                      )
                    : const Text('Guardar cambio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}