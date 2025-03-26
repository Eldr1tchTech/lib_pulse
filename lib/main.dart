import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/login_screen.dart'; // We'll create this next

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Enable caching for better offline experience
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(
    const BookCatalogApp(),
  );
}

class BookCatalogApp extends StatelessWidget {
  const BookCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Book Catalog',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _handleAuth(),
    );
  }
  
  // Check if user is authenticated and route accordingly
  Widget _handleAuth() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If we have a user, go to HomeScreen, otherwise go to LoginScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}