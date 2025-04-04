import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    // Add this to fix keyboard focus issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any focus when the screen loads
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Wrap the entire screen in a GestureDetector to dismiss keyboard
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Book Catalog')),
        body: FutureBuilder<List<Book>>(
          future: _fetchBooks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            final books = snapshot.data ?? [];
            if (books.isEmpty) {
              return const Center(child: Text('No books found'));
            }
            
            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.author),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  // Safe method to fetch books with proper error handling
  Future<List<Book>> _fetchBooks() async {
    try {
      debugPrint('building catalog');
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .get()
          .timeout(const Duration(seconds: 10));
      
      return snapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      debugPrint('Error fetching books: $e');
      debugPrint(stack.toString());
      // Return empty list instead of crashing
      return [];
    }
  }
} 