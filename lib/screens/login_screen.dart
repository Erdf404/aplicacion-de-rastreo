import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _modoOffline =
      true; // Cambiar a false cuando se tenga el backend y borrar la opción ofline

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            _cajaarriba(size),
            _cajalogin(size, context),
            _logoescuela(size),
            // Overlay de carga
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Descargando datos...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SafeArea _logoescuela(Size size) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: size.height * 0.05),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: size.height * 0.15,
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/ca/TSJZapopan_Logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SingleChildScrollView _cajalogin(Size size, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: size.height * 0.35),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(5, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text('Login', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      // Campo de correo
                      TextFormField(
                        controller: _emailController,
                        autocorrect: false,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          String pattern =
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                          RegExp regExp = RegExp(pattern);
                          return regExp.hasMatch(value ?? '')
                              ? null
                              : 'Correo electrónico inválido';
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      // Campo de contraseña
                      TextFormField(
                        controller: _passController,
                        autocorrect: false,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          return (value != null && value.length >= 6)
                              ? null
                              : 'La contraseña es de mínimo 6 caracteres';
                        },
                      ),
                      const SizedBox(height: 20),

                      // Botón de login
                      MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledColor: Colors.grey,
                        color: Colors.deepPurple,
                        onPressed: _isLoading ? null : _handleLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 70,
                            vertical: 20,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),

                      // Switch para modo offline Eliminar cuando se tenga el backend
                      if (_modoOffline) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Modo Offline (Desarrollo)',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          const Text(
            'Para recuperar la contraseña\npídesela a tu administrador',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Container _cajaarriba(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
        ),
      ),
      width: double.infinity,
      height: size.height * 0.4,
    );
  }

  Future<void> _handleLogin() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Obtener UserSession del Provider
    final userSession = Provider.of<UserSession>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> resultado;

      // Login según modo
      if (_modoOffline) {
        // Modo offline (desarrollo)
        resultado = await _authService.loginOffline(
          correo: _emailController.text.trim(),
          contrasena: _passController.text,
          userSession: userSession,
        );
      } else {
        // Modo online (producción)
        resultado = await _authService.login(
          correo: _emailController.text.trim(),
          contrasena: _passController.text,
          userSession: userSession,
        );
      }

      setState(() => _isLoading = false);

      if (resultado['success']) {
        // Login exitoso
        if (mounted) {
          _mostrarMensaje('¡Bienvenido ${userSession.nombre}!', Colors.green);

          // Navegar a opciones rondines
          Navigator.pushReplacementNamed(context, 'opciones_rondines');
        }
      } else {
        // Login fallido
        if (mounted) {
          _mostrarMensaje(
            resultado['message'] ?? 'Error desconocido',
            Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _mostrarMensaje('Error inesperado: ${e.toString()}', Colors.red);
      }
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
