import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/persone_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/persone_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PersoneProvider()),
      ],
      child: MaterialApp(
        title: 'aGene - Albero Genealogico',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Widget wrapper per gestire l'autenticazione
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Se l'utente è autenticato, mostra la lista persone
        // Altrimenti mostra la schermata di login
        if (authProvider.isAuthenticated) {
          return const PersoneListScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
