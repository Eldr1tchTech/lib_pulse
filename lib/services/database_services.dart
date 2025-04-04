// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/copy.dart';
import '/models/book.dart';
import '/models/series.dart';
import '/models/customer.dart';

const String BOOKS_COLLECTION_REF = "books";
const String SERIES_COLLECTION_REF = "series";
const String COPIES_COLLECTION_REF = "copies";
const String CONFIG_COLLECTION_REF = "config";
const String CUSTOMERS_COLLECTION_REF = "customers";

class DatabaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Book> _booksRef;
  late final CollectionReference<Series> _seriesRef;
  late final CollectionReference<Copy> _copiesRef;
  late final CollectionReference _configRef;
  late final CollectionReference<Customer> _customersRef;

  FirebaseFirestore get firestore => _firestore;
  CollectionReference<Book> get booksRef => _booksRef;
  CollectionReference<Customer> get customersRef => _customersRef;
  CollectionReference<Copy> get copiesRef => _copiesRef;
  CollectionReference<Series> get seriesRef => _seriesRef;

  DatabaseServices() {
    _booksRef = _firestore.collection(BOOKS_COLLECTION_REF).withConverter<Book>(
          fromFirestore: (snapshots, _) => Book.fromJson(
            snapshots.data()!,
          ),
          toFirestore: (book, _) => book.toJson(),
        );
    _seriesRef =
        _firestore.collection(SERIES_COLLECTION_REF).withConverter<Series>(
              fromFirestore: (snapshots, _) => Series.fromJson(
                snapshots.data()!,
              ),
              toFirestore: (series, _) => series.toJson(),
            );
    _copiesRef =
        _firestore.collection(COPIES_COLLECTION_REF).withConverter<Copy>(
              fromFirestore: (snapshots, _) {
                final data = snapshots.data()!;
                return Copy.fromJson(
                  data,
                  reference: snapshots.reference
                      as DocumentReference<Copy>, // Cast the reference
                );
              },
              toFirestore: (copy, _) => copy.toJson(),
            );
    _customersRef =
        _firestore.collection(CUSTOMERS_COLLECTION_REF).withConverter<Customer>(
              fromFirestore: (snapshots, _) => Customer.fromJson(
                snapshots.data()!,
              ),
              toFirestore: (customer, _) => customer.toJson(),
            );
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

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(copyRef);

      if (!docSnapshot.exists) {
        throw Exception("Copy document does not exist."); // Handle missing doc
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
        return await copiesRef.where('bookRef', isEqualTo: bookRef).get();
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

    await _firestore.runTransaction((transaction) async {
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

  Stream<List<Book>> filterBooks(String searchQuery) {
    return _booksRef
        .where('title', isGreaterThanOrEqualTo: searchQuery)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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

  Future<void> addCopy(Copy copy) async {
    final newCopyRef = _copiesRef.doc();
    await newCopyRef.set(copy);
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
}