import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/firestore_service.dart';
import '/models/copy.dart';
import '/models/book.dart';
import '/models/series.dart';
import '/models/customer.dart';

// Constants remain the same
const String BOOKS_COLLECTION_REF = "books";
const String SERIES_COLLECTION_REF = "series";
const String COPIES_COLLECTION_REF = "copies";
const String CONFIG_COLLECTION_REF = "config";
const String CUSTOMERS_COLLECTION_REF = "customers";

class DatabaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Collection references
  late final CollectionReference<Book> _booksRef;
  late final CollectionReference<Series> _seriesRef;
  late final CollectionReference<Copy> _copiesRef;
  late final CollectionReference _configRef;
  late final CollectionReference<Customer> _customersRef;

  // Getters for collection references
  CollectionReference<Series> get seriesRef {
    return _seriesRef;
  }

  // Getters remain the same but use _firestoreService
  CollectionReference<Book> get booksRef {
    return _booksRef;
  }

  DatabaseServices() {
    _initializeCollections();
  }

  void _initializeCollections() {
    final firestore = _firestoreService.firestore;

    // Initialize all collections using the firestore service
    _booksRef = firestore.collection(BOOKS_COLLECTION_REF).withConverter<Book>(
          fromFirestore: (snapshots, _) {
            try {
              final data = snapshots.data();
              if (data == null) {
                throw Exception("Document data is null");
              }
              return Book.fromJson(data);
            } catch (e) {
              print('Error converting Book from Firestore: $e');
              rethrow;
            }
          },
          toFirestore: (book, _) => book.toJson(),
        );

    _copiesRef =
        firestore.collection(COPIES_COLLECTION_REF).withConverter<Copy>(
              fromFirestore: (snapshots, _) {
                try {
                  final data = snapshots.data();
                  if (data == null) {
                    throw Exception("Document data is null");
                  }
                  return Copy.fromJson(data);
                } catch (e) {
                  print('Error converting Copy from Firestore: $e');
                  rethrow;
                }
              },
              toFirestore: (copy, _) => copy.toJson(),
            );

    _seriesRef =
        firestore.collection(SERIES_COLLECTION_REF).withConverter<Series>(
              fromFirestore: (snapshots, _) {
                try {
                  final data = snapshots.data();
                  if (data == null) {
                    throw Exception("Document data is null");
                  }
                  return Series.fromJson(data);
                } catch (e) {
                  print('Error converting Series from Firestore: $e');
                  rethrow;
                }
              },
              toFirestore: (series, _) => series.toJson(),
            );

    _customersRef =
        firestore.collection(CUSTOMERS_COLLECTION_REF).withConverter<Customer>(
              fromFirestore: (snapshots, _) {
                try {
                  final data = snapshots.data();
                  if (data == null) {
                    throw Exception("Document data is null");
                  }
                  return Customer.fromJson(data);
                } catch (e) {
                  print('Error converting Customer from Firestore: $e');
                  rethrow;
                }
              },
              toFirestore: (customer, _) => customer.toJson(),
            );
  }

  Future<void> addBookCopy(Book book) async {
  try {
    // Use the FirestoreService to ensure operations run on the platform thread
    await _firestoreService.execute(() async {
      final docRef = _copiesRef.doc();
      
      final newCopy = Copy(
        id: docRef.id,
        bookRef: booksRef.doc(book.id),
        dateAcquired: DateTime.now(),
        available: true,
        loanRefs: [],
      );
      
      await docRef.set(newCopy);
      return true; // Return value needed for execute<T>
    });
  } catch (e) {
    print('Error adding book copy: $e');
    rethrow; // Rethrow to allow proper error handling upstream
  }
}

  Future<void> addCopy(String isbn) async {
  try {
    await _firestoreService.execute(() async {
      final bookRef = _booksRef.doc(isbn);
      final docRef = _copiesRef.doc();

      final newCopy = Copy(
        id: docRef.id,
        bookRef: bookRef,
        dateAcquired: DateTime.now(),
        available: true,
        loanRefs: [],
      );

      await docRef.set(newCopy);
      return true;
    });
  } catch (e) {
    print('Error adding copy: $e');
    rethrow;
  }
}

  Stream<List<Book>> filterBooks(String searchQuery) {
    try {
      var query = _booksRef.orderBy('title').limit(10);

      if (searchQuery.isNotEmpty) {
        query = query.where('title', isGreaterThanOrEqualTo: searchQuery);
      }

      return _firestoreService
          .streamCollection(query)
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((error) {
        print('Error in filterBooks: $error');
        return <Book>[];
      });
    } catch (e) {
      print('Error setting up filterBooks stream: $e');
      return Stream.value(<Book>[]);
    }
  }

  Stream<QuerySnapshot> getBooks() {
    return _booksRef.snapshots();
  }

  Future<void> addBook(Book book) async {
    final newBookRef = _booksRef.doc();
    await newBookRef.set(book);
  }

  Future<void> updateBook(String bookId, Book book) async {
    await _booksRef.doc(bookId).update(book.toJson());
  }

  Future<void> deleteBook(String bookId) async {
    await _booksRef.doc(bookId).delete();
  }

  Future<bool> hasCopy(int id) async {
    var result = await _copiesRef.where('id', isEqualTo: id).get();
    return result.docs.isNotEmpty;
  }

  Future<bool> hasCustomer(int id) async {
    var result = await _customersRef.where('id', isEqualTo: id).get();
    return result.docs.isNotEmpty;
  }

  Future<void> borrowCopy(int copyId, int customerId) async {
    final copyRef = _copiesRef.doc(copyId.toString());

    await _firestoreService.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(copyRef);

      if (!docSnapshot.exists) {
        throw Exception("Copy document does not exist.");
      }

      transaction.update(copyRef, {
        'available': false,
        'borrowedBy': customerId,
        'borrowDate': DateTime.now(),
      });
    });
  }

  Future<(int, int)> availability(Book book) async {
    try {
      DocumentReference<Book> bookRef = booksRef.doc(book.id);

      // Wrap the query in a Future to ensure it runs on the platform thread
      final querySnapshot = await Future(() async {
        return await _copiesRef.where('bookRef', isEqualTo: bookRef).get();
      });

      int total = querySnapshot.size;
      int available = querySnapshot.docs.where((doc) {
        try {
          final copy = doc.data();
          return copy.available;
        } catch (e) {
          // Use a logger instead of print in production
          // TODO: Replace with a proper logging mechanism
          print('Error processing copy: $e');
          return false;
        }
      }).length;

      return (available, total);
    } catch (e) {
      // Use a logger instead of print in production
      // TODO: Replace with a proper logging mechanism
      print('Error in availability: $e');
      return (0, 0);
    }
  }

  Future<void> returnCopy(int copyId) async {
    final copyRef = _copiesRef.doc(copyId.toString());

    await _firestoreService.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(copyRef);

      if (!docSnapshot.exists) {
        throw Exception("Copy document does not exist."); // Handle missing doc
      }

      transaction.update(copyRef, {
        'available': true,
        'borrowedBy': FieldValue.delete(),
        'borrowDate': FieldValue.delete(),
        'returnDate': DateTime.now(),
      });
    });
  }

  Stream<List<Customer>> filterCustomers(String searchQuery) {
    return _customersRef
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addCustomer(Customer customer) async {
    final newCustomerRef = _customersRef.doc();
    await newCustomerRef.set(customer);
  }

  Future<Series?> getSeriesFromPath(String path) async {
    final seriesRef = FirebaseFirestore.instance.doc(path);
    final seriesSnapshot = await seriesRef.get();
    final data = seriesSnapshot.data();

    if (data != null) {
      return Series.fromJson(data);
    }
    return null;
  }

  Future<List<Series>> getAllSeries() async {
    final snapshot = await _seriesRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Book>> overdueBooks() {
    final now = DateTime.now();
    return _booksRef
        .where('dueDate', isLessThan: now)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Copy>> allCopies() {
    return _copiesRef
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<Book?> getBook(String bookId) async {
    final docSnapshot = await _booksRef.doc(bookId).get();
    return docSnapshot.data();
  }

  Future<Series?> getSeries(String seriesId) async {
    final docSnapshot = await _seriesRef.doc(seriesId).get();
    return docSnapshot.data();
  }

  Future<List<Copy>> getCopies(String bookId) async {
    final querySnapshot = await _copiesRef
        .where('bookRef', isEqualTo: _booksRef.doc(bookId))
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // In DatabaseServices class
  Future<Map<String, (int, int)>> getAllBooksAvailability() async {
    try {
      final querySnapshot = await _copiesRef.get();

      // Group copies by book reference
      Map<String, List<Copy>> copiesByBook = {};
      for (var doc in querySnapshot.docs) {
        try {
          final copy = doc.data();
          String bookId = copy.bookRef.id;
          if (!copiesByBook.containsKey(bookId)) {
            copiesByBook[bookId] = [];
          }
          copiesByBook[bookId]!.add(copy);
        } catch (e) {
          print('Error processing copy: $e');
        }
      }

      // Calculate availability for each book
      Map<String, (int, int)> result = {};
      copiesByBook.forEach((bookId, copies) {
        int total = copies.length;
        int available = copies.where((copy) => copy.available).length;
        result[bookId] = (available, total);
      });

      return result;
    } catch (e) {
      print('Error getting all books availability: $e');
      return {};
    }
  }

  Future<DocumentReference<Copy>> copiesRef() async {
  return _firestoreService.execute(() => Future.value(_copiesRef.doc()));
}
}
