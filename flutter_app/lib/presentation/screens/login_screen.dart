import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/biometric_service.dart';
import '../providers/auth_provider.dart';
import 'persone_list_screen.dart';

/// Schermata di login con supporto per autenticazione biometrica
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkBiometricEnabled();
    _checkAutoLogin();
  }

  /// Verifica se l'autenticazione biometrica è disponibile
  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  /// Verifica se l'autenticazione biometrica è abilitata
  Future<void> _checkBiometricEnabled() async {
    final enabled = await _biometricService.isBiometricEnabled();
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  /// Verifica se può fare auto-login con biometrica
  Future<void> _checkAutoLogin() async {
    if (_biometricEnabled && await _biometricService.isAuthStillValid()) {
      // L'autenticazione è ancora valida, vai direttamente alla lista
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PersoneListScreen()),
        );
      });
    }
  }

  /// Gestisce il login tradizionale
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        // Se l'autenticazione biometrica è disponibile, chiedi se abilitarla
        if (_biometricAvailable && !_biometricEnabled) {
          _showBiometricEnableDialog();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PersoneListScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenziali non valide'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il login: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Gestisce il login biometrico
  Future<void> _handleBiometricLogin() async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Autenticati per accedere all\'app',
    );

    if (authenticated && mounted) {
      // Per ora, in modalità offline, accetta sempre
      // In futuro, qui si può aggiungere la verifica delle credenziali salvate
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PersoneListScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticazione biometrica fallita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostra il dialog per abilitare l'autenticazione biometrica
  void _showBiometricEnableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abilita autenticazione biometrica'),
        content: const Text(
          'Vuoi abilitare l\'autenticazione biometrica per un accesso più rapido?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PersoneListScreen()),
              );
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await _biometricService.enableBiometric();
              Navigator.of(context).pop();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PersoneListScreen()),
                );
              }
            },
            child: const Text('Sì'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 80.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.family_restroom,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'aGene',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Albero Genealogico',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci l\'email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci la password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Accedi'),
                  ),
                  if (_biometricAvailable && _biometricEnabled) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Accedi con impronta digitale'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

