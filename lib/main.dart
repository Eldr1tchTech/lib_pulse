import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/book.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/home.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      debugPrint('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
      
      // Use more conservative Firestore settings for Windows
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 10485760, // 10MB cache instead of unlimited
      );
      
      runApp(const BookCatalogApp());
    } catch (e, stack) {
      debugPrint('Error initializing app: $e');
      debugPrint(stack.toString());
      // Show error screen instead of crashing
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Error initializing app: $e'),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('Unhandled error: $error');
    debugPrint(stack.toString());
  });
}

class BookCatalogApp extends StatelessWidget {
  const BookCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Book Catalog',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

// Example of how to structure Firestore calls in your catalog page
Future<List<Book>> fetchBooks() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .get()
        .timeout(const Duration(seconds: 10)); // Add timeout
    
    return snapshot.docs
        .map((doc) => Book.fromFirestore(doc))
        .toList();
  } catch (e, stack) {
    debugPrint('Error fetching books: $e');
    debugPrint(stack.toString());
    // Return empty list or throw a user-friendly error
    return [];
  }
}