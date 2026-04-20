import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_notification_service.dart';
import '../data/current_user_session.dart';
import '../data/reservation_repository.dart';
import '../data/user_database.dart';
import 'cliente1.dart';
import 'trabajador1.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const int _maxFailedLoginAttempts = 5;
  static const Duration _loginLockoutDuration = Duration(minutes: 15);
  static const String _failedLoginAttemptsKey = 'login.failed_attempts';
  static const String _loginLockoutUntilKey = 'login.lockout_until';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerCityController = TextEditingController();
  final TextEditingController _registerPhoneController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _registerNameFocusNode = FocusNode();
  final FocusNode _registerEmailFocusNode = FocusNode();
  final FocusNode _registerCityFocusNode = FocusNode();
  final FocusNode _registerPhoneFocusNode = FocusNode();
  final FocusNode _registerPasswordFocusNode = FocusNode();

  bool _isRegisterMode = false;
  bool _isPasswordVisible = false;
  bool _isRegisterPasswordVisible = false;
  bool _isLoading = false;
  String? _loginErrorMessage;
  DateTime? _loginLockoutUntil;
  Timer? _lockoutTimer;

  bool get _isLoginLocked {
    final lockoutUntil = _loginLockoutUntil;
    return lockoutUntil != null && DateTime.now().isBefore(lockoutUntil);
  }

  Duration? get _remainingLockoutDuration {
    final lockoutUntil = _loginLockoutUntil;
    if (lockoutUntil == null) {
      return null;
    }

    final remaining = lockoutUntil.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      return null;
    }

    return remaining;
  }

  @override
  void initState() {
    super.initState();
    _restoreLoginLockoutState();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerCityController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _registerNameFocusNode.dispose();
    _registerEmailFocusNode.dispose();
    _registerCityFocusNode.dispose();
    _registerPhoneFocusNode.dispose();
    _registerPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  Future<void> _restoreLoginLockoutState() async {
    final prefs = await _prefs();
    final lockoutUntilMillis = prefs.getInt(_loginLockoutUntilKey);

    if (lockoutUntilMillis == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginLockoutUntil = null;
      });
      return;
    }

    final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMillis);
    if (DateTime.now().isAfter(lockoutUntil)) {
      await prefs.remove(_loginLockoutUntilKey);
      await prefs.remove(_failedLoginAttemptsKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _loginLockoutUntil = null;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loginLockoutUntil = lockoutUntil;
      _loginErrorMessage = _buildLockoutMessage(lockoutUntil);
    });

    _startLockoutTimer();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remaining = _remainingLockoutDuration;
      if (remaining == null) {
        final prefs = await _prefs();
        await prefs.remove(_loginLockoutUntilKey);
        await prefs.remove(_failedLoginAttemptsKey);
        setState(() {
          _loginLockoutUntil = null;
          if (_loginErrorMessage != null && _loginErrorMessage!.contains('Bloqueo activo')) {
            _loginErrorMessage = null;
          }
        });
        timer.cancel();
        return;
      }

      setState(() {
        _loginErrorMessage = _buildLockoutMessage(_loginLockoutUntil!);
      });
    });
  }

  Future<void> _clearLoginSecurityState() async {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    _loginLockoutUntil = null;

    final prefs = await _prefs();
    await prefs.remove(_failedLoginAttemptsKey);
    await prefs.remove(_loginLockoutUntilKey);
  }

  Future<void> _registerFailedLoginAttempt(String loginError) async {
    final prefs = await _prefs();
    final failedAttempts = (prefs.getInt(_failedLoginAttemptsKey) ?? 0) + 1;

    if (failedAttempts >= _maxFailedLoginAttempts) {
      final lockoutUntil = DateTime.now().add(_loginLockoutDuration);
      await prefs.setInt(_loginLockoutUntilKey, lockoutUntil.millisecondsSinceEpoch);
      await prefs.setInt(_failedLoginAttemptsKey, 0);

      if (!mounted) {
        return;
      }

      setState(() {
        _loginLockoutUntil = lockoutUntil;
        _loginErrorMessage = _buildLockoutMessage(lockoutUntil);
      });
      _startLockoutTimer();
      _showSnackBar('Demasiados intentos fallidos. Acceso bloqueado durante 15 minutos.');
      return;
    }

    await prefs.setInt(_failedLoginAttemptsKey, failedAttempts);

    if (!mounted) {
      return;
    }

    setState(() {
      _loginErrorMessage = loginError == 'Contraseña incorrecta'
          ? '*Error en la contraseña'
          : '*$loginError';
    });
  }

  String _buildLockoutMessage(DateTime lockoutUntil) {
    final remaining = lockoutUntil.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    final formattedMinutes = minutes.toString().padLeft(2, '0');
    final formattedSeconds = seconds.toString().padLeft(2, '0');

    return '*Bloqueo activo. Vuelve a intentarlo en $formattedMinutes:$formattedSeconds minutos.';
  }

  Future<void> _login() async {
    final prefs = await _prefs();
    final lockoutUntilMillis = prefs.getInt(_loginLockoutUntilKey);

    if (lockoutUntilMillis != null) {
      final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMillis);
      if (DateTime.now().isBefore(lockoutUntil)) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loginLockoutUntil = lockoutUntil;
          _loginErrorMessage = _buildLockoutMessage(lockoutUntil);
        });

        _startLockoutTimer();
        _showSnackBar('Demasiados intentos fallidos. Intenta de nuevo más tarde.');
        return;
      }

      await prefs.remove(_loginLockoutUntilKey);
      await prefs.remove(_failedLoginAttemptsKey);
      if (!mounted) {
        return;
      }

      setState(() {
        _loginLockoutUntil = null;
      });
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnackBar('Por favor ingresa tu correo electronico');
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Por favor ingresa tu contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _loginErrorMessage = null;
    });

    try {
      Widget? destination;
      String? loginError;

      // Mantiene tus usuarios de demo actuales.
      if (email == 'trabajador@gmail.com') {
        if (password == 'password') {
          destination = const WorkerMainScreen();
        } else {
          loginError = 'Contraseña incorrecta';
        }
      } else if (email == 'cliente@gmail.com') {
        if (password == 'password') {
          destination = const MainScreen();
        } else {
          loginError = 'Contraseña incorrecta';
        }
      } else {
        final userExists = await UserDatabase.instance.userExists(email);

        if (!userExists) {
          loginError = 'Correo no registrado';
        } else {
          final isValid = await UserDatabase.instance.validateCredentials(
            email: email,
            password: password,
          );
          if (isValid) {
            destination = const MainScreen();
          } else {
            loginError = 'Contraseña incorrecta';
          }
        }
      }

      if (destination == null) {
        if (loginError != null) {
          await _registerFailedLoginAttempt(loginError);
        }
        _showSnackBar(loginError ?? 'No se pudo iniciar sesion');
        return;
      }

      if (!mounted) return;
      await _clearLoginSecurityState();
      setState(() {
        _loginErrorMessage = null;
      });
      await CurrentUserSession.instance.setCurrentUserEmail(email);
      if (email != 'trabajador@gmail.com') {
        await ReservationRepository.instance.loadCurrentUserReservations();
        await AppNotificationService.instance.processPendingNotificationsForCurrentUser(
          reservations: ReservationRepository.instance.reservations.value,
        );
      } else {
        await ReservationRepository.instance.clearLoadedReservations();
        await AppNotificationService.instance
            .processPendingNotificationsForCurrentUser();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination!),
      );
    } catch (e) {
      _showSnackBar('No se pudo iniciar sesion: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim().toLowerCase();
    final city = _registerCityController.text.trim();
    final phone = _registerPhoneController.text.trim();
    final password = _registerPasswordController.text;

    if (name.isEmpty) {
      _showSnackBar('Por favor ingresa tu nombre');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Por favor ingresa un correo valido');
      return;
    }
    if (city.isEmpty) {
      _showSnackBar('Por favor ingresa tu ciudad');
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('Por favor ingresa tu numero de telefono');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await UserDatabase.instance.createUser(
        name: name,
        email: email,
        city: city,
        phone: phone,
        password: password,
      );

      _showSnackBar('Usuario registrado correctamente');

      _emailController.text = email;
      _passwordController.clear();

      if (mounted) {
        setState(() {
          _isRegisterMode = false;
          _registerNameController.clear();
          _registerEmailController.clear();
          _registerCityController.clear();
          _registerPhoneController.clear();
          _registerPasswordController.clear();
        });
      }
    } on StateError catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('No se pudo registrar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _toggleRegisterPasswordVisibility() {
    setState(() {
      _isRegisterPasswordVisible = !_isRegisterPasswordVisible;
    });
    _registerPasswordFocusNode.requestFocus();
  }

  void _toggleLoginPasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
    _passwordFocusNode.requestFocus();
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text.trim());

    final String? email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                emailController.text.trim().toLowerCase(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (email == null || email.isEmpty) {
      return;
    }

    final exists = await UserDatabase.instance.userExists(email);
    if (!mounted) return;

    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existe un usuario con ese correo.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Se ha enviado un correo para renovar la contraseña. La función real se añadirá después.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1600&q=80',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.landscape,
                        size: 48,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GreenScape',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camina, descubre, comparte.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAuthCard(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.hiking,
                            label: 'RUTAS',
                            value: '12,482',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.thermostat,
                            label: 'TEMPERATURA',
                            value: '21C',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            selected: !_isRegisterMode,
            label: 'Iniciar sesión',
            onTap: () {
              setState(() {
                _isRegisterMode = false;
              });
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildModeButton(
            selected: _isRegisterMode,
            label: 'Registrarse',
            onTap: () {
              setState(() {
                _isRegisterMode = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.green.shade700 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.green.shade700 : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeSelector(),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isRegisterMode ? _buildRegisterForm() : _buildLoginForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      children: [
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          onChanged: (_) {
            if (_loginErrorMessage != null && !_isLoginLocked) {
              setState(() {
                _loginErrorMessage = null;
              });
            }
          },
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            label: 'Correo electronico',
            hint: 'ejemplo@correo.com',
            icon: Icons.email_outlined,
            showHint: !_emailFocusNode.hasFocus,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          key: ValueKey('login_password_$_isPasswordVisible'),
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          onChanged: (_) {
            if (_loginErrorMessage != null && !_isLoginLocked) {
              setState(() {
                _loginErrorMessage = null;
              });
            }
          },
          obscureText: !_isPasswordVisible,
          decoration: _inputDecoration(
            label: 'Contraseña',
            hint: '••••••••',
            icon: Icons.lock_outline,
            showHint: !_passwordFocusNode.hasFocus,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: _toggleLoginPasswordVisibility,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _forgotPassword,
            child: const Text('¿Has olvidado la contraseña?'),
          ),
        ),
        if (_loginErrorMessage != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _loginErrorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || _isLoginLocked) ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
        if (_isLoginLocked) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _loginErrorMessage ?? '*Bloqueo activo temporalmente',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register_form'),
      children: [
        TextField(
          controller: _registerNameController,
          focusNode: _registerNameFocusNode,
          decoration: _inputDecoration(
            label: 'Nombre',
            hint: 'Tu nombre completo',
            icon: Icons.person_outline,
            showHint: !_registerNameFocusNode.hasFocus,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _registerEmailController,
          focusNode: _registerEmailFocusNode,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            label: 'Correo electronico',
            hint: 'ejemplo@correo.com',
            icon: Icons.email_outlined,
            showHint: !_registerEmailFocusNode.hasFocus,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _registerCityController,
          focusNode: _registerCityFocusNode,
          decoration: _inputDecoration(
            label: 'Ciudad',
            hint: 'Sevilla',
            icon: Icons.location_city_outlined,
            showHint: !_registerCityFocusNode.hasFocus,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _registerPhoneController,
          focusNode: _registerPhoneFocusNode,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            label: 'Numero de telefono',
            hint: '+34 612 345 678',
            icon: Icons.phone_outlined,
            showHint: !_registerPhoneFocusNode.hasFocus,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: ValueKey('register_password_$_isRegisterPasswordVisible'),
          controller: _registerPasswordController,
          focusNode: _registerPasswordFocusNode,
          obscureText: !_isRegisterPasswordVisible,
          decoration: _inputDecoration(
            label: 'Contraseña',
            hint: 'Minimo 6 caracteres',
            icon: Icons.lock_outline,
            showHint: !_registerPasswordFocusNode.hasFocus,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _isRegisterPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: _toggleRegisterPasswordVisibility,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Crear cuenta',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool showHint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: showHint ? hint : '',
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green.shade700, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
