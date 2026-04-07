import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import 'area_profesional_view.dart';
import 'familiar_dashboard_view.dart';
import 'medico_dashboard_view.dart';
import 'panel_control_view.dart';
import 'admin_aprobaciones_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _authService = AuthService();

  bool _esRegistro = false;
  bool _cargando = false;
  String _rolSeleccionado = RolesVitta.familiar;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3E6F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                "VITTA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                "Cuidado con confianza",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Card del formulario
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [

                    // Nombre (solo en registro)
                    if (_esRegistro) ...[
                      TextField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selector de rol — etiquetas UI: Familiar / Profesional.
                      // En Firestore `usuarios/{uid}.rol` = RolesVitta.familiar | RolesVitta.profesional.
                      const Text('Soy:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'Familiar',
                              selected: _rolSeleccionado == RolesVitta.familiar,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _rolSeleccionado = RolesVitta.familiar),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _rolSeleccionado == RolesVitta.familiar
                                        ? const Color(0xFF1A3E6F)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF1A3E6F)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.family_restroom,
                                        color: _rolSeleccionado == RolesVitta.familiar
                                            ? Colors.white
                                            : const Color(0xFF1A3E6F)),
                                      const SizedBox(height: 4),
                                      Text('Familiar',
                                        style: TextStyle(
                                          color: _rolSeleccionado == RolesVitta.familiar
                                              ? Colors.white
                                              : const Color(0xFF1A3E6F),
                                          fontWeight: FontWeight.bold,
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'Profesional',
                              selected: _rolSeleccionado == RolesVitta.profesional,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _rolSeleccionado = RolesVitta.profesional),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _rolSeleccionado == RolesVitta.profesional
                                        ? const Color(0xFF1A3E6F)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF1A3E6F)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.medical_services,
                                        color: _rolSeleccionado == RolesVitta.profesional
                                            ? Colors.white
                                            : const Color(0xFF1A3E6F)),
                                      const SizedBox(height: 4),
                                      Text('Profesional',
                                        style: TextStyle(
                                          color: _rolSeleccionado == RolesVitta.profesional
                                              ? Colors.white
                                              : const Color(0xFF1A3E6F),
                                          fontWeight: FontWeight.bold,
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],

                    const SizedBox(height: 24),

                    // Boton principal
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _cargando ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3E6F),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _cargando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _esRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cargando ? null : _loginGoogle,
                        icon: SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.network(
                            'https://www.google.com/favicon.ico',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              size: 18,
                              color: Color(0xFF1A3E6F),
                            ),
                          ),
                        ),
                        label: const Text('Continuar con Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A3E6F),
                          side: const BorderSide(color: Color(0xFF1A3E6F)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cambiar entre login y registro
                    TextButton(
                      onPressed: () => setState(() {
                        _esRegistro = !_esRegistro;
                        _error = null;
                      }),
                      child: Text(
                        _esRegistro
                            ? '¿Ya tenés cuenta? Iniciá sesión'
                            : '¿No tenés cuenta? Registrate',
                        style: const TextStyle(color: Color(0xFF1A3E6F)),
                      ),
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _cargando
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MedicoDashboardView(),
                            ),
                          );
                        },
                  child: const Text(
                    '[Debug] Ir a MedicoDashboardView',
                    style: TextStyle(
                      color: Color(0xFFB3C5E0),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    if (_esRegistro) {
      // AuthService.registrar persiste `rol` en usuarios/{uid} (p. ej. RolesVitta.profesional).
      final usuario = await _authService.registrar(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
        rol: _rolSeleccionado,
      );

      if (usuario != null && mounted) {
        _navegarSegunRol(usuario.rol);
      } else {
        setState(() => _error = 'Error al crear la cuenta. Verificá los datos.');
      }
    } else {
      final usuario = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (usuario != null && mounted) {
        _navegarSegunRol(usuario.rol);
      } else {
        setState(() => _error = 'Email o contraseña incorrectos.');
      }
    }

    setState(() => _cargando = false);
  }

  void _navegarSegunRol(String rol) {
    if (rol == RolesVitta.medico) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MedicoDashboardView()),
      );
    } else if (rol == RolesVitta.enfermeroN3 || rol == RolesVitta.profesional) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AreaProfesionalView()),
      );
    } else if (rol == RolesVitta.familiar) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FamiliarDashboardView()),
      );
    } else if (rol == RolesVitta.admin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminAprobacionesView()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PanelControlView()),
      );
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final usuario = await _authService.loginConGoogle();

    if (!mounted) return;

    if (usuario != null) {
      _navegarSegunRol(usuario.rol);
    } else {
      setState(() => _error = 'No se pudo iniciar sesión con Google.');
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }
}