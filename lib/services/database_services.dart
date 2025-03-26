// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/copy.dart';
import '/models/book.dart';
import '/models/series.dart';
import '/models/customer.dart';
import 'dart:async';

const String BOOKS_COLLECTION_REF = "books";
const String SERIES_COLLECTION_REF = "series";
const String COPIES_COLLECTION_REF = "copies";
const String CONFIG_COLLECTION_REF = "config";
const String CUSTOMERS_COLLECTION_REF = "customers";

class DatabaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<Book> _booksRef;
  late final CollectionReference<Series> _seriesRef;
  late final CollectionReference<Copy> _copiesRef;
  late final CollectionReference _configRef;
  late final CollectionReference<Customer> _customersRef;
  
  // Make these getters check for authentication
  CollectionReference<Book> get booksRef {
    _checkAuthentication();
    return _booksRef;
  }
  
  CollectionReference<Customer> get customersRef {
    _checkAuthentication();
    return _customersRef;
  }
  
  CollectionReference<Copy> get copiesRef {
    _checkAuthentication();
    return _copiesRef;
  }
  
  CollectionReference<Series> get seriesRef {
    _checkAuthentication();
    return _seriesRef;
  }
  
  FirebaseFirestore get firestore {
    _checkAuthentication();
    return _firestore;
  }

  // Add authentication check
  void _checkAuthentication() {
    if (_auth.currentUser == null) {
      throw Exception("User is not authenticated. Please sign in.");
    }
  }

  DatabaseServices() {
    _initializeCollections();
  }
  
  void _initializeCollections() {
    _booksRef = _firestore.collection(BOOKS_COLLECTION_REF).withConverter<Book>(
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
        
    _seriesRef = _firestore.collection(SERIES_COLLECTION_REF).withConverter<Series>(
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
        
    _copiesRef = _firestore.collection(COPIES_COLLECTION_REF).withConverter<Copy>(
          fromFirestore: (snapshots, _) {
            try {
              final data = snapshots.data();
              if (data == null) {
                throw Exception("Document data is null");
              }
              return Copy.fromJson(
                data,
                reference: snapshots.reference as DocumentReference<Copy>,
              );
            } catch (e) {
              print('Error converting Copy from Firestore: $e');
              rethrow;
            }
          },
          toFirestore: (copy, _) => copy.toJson(),
        );
        
    _customersRef = _firestore.collection(CUSTOMERS_COLLECTION_REF).withConverter<Customer>(
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
        
    _configRef = _firestore.collection(CONFIG_COLLECTION_REF);
  }

  // Wrap streams in error handling
  Stream<List<Book>> filterBooks(String searchQuery) {
    try {
      _checkAuthentication();
      return _booksRef
          .where('title', isGreaterThanOrEqualTo: searchQuery)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((error) {
            print('Error in filterBooks: $error');
            // Return empty list instead of crashing
            return <Book>[];
          });
    } catch (e) {
      print('Error setting up filterBooks stream: $e');
      // Return empty stream
      return Stream.value(<Book>[]);
    }
  }

  Stream<List<Customer>> filterCustomers(String searchQuery) {
    try {
      _checkAuthentication();
      return _customersRef
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((error) {
            print('Error in filterCustomers: $error');
            return <Customer>[];
          });
    } catch (e) {
      print('Error setting up filterCustomers stream: $e');
      return Stream.value(<Customer>[]);
    }
  }

  Future<bool> hasCopy(int id) async {
    try {
      _checkAuthentication();
      var result = await _copiesRef.where('id', isEqualTo: id.toString()).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error in hasCopy: $e');
      return false;
    }
  }

  Future<bool> hasCustomer(int id) async {
    try {
      _checkAuthentication();
      var result = await _customersRef.where('id', isEqualTo: id.toString()).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error in hasCustomer: $e');
      return false;
    }
  }

  Future<void> addBook(Book book) async {
    try {
      _checkAuthentication();
      final newBookRef = _booksRef.doc();
      await newBookRef.set(book);
    } catch (e) {
      print('Error adding book: $e');
      rethrow;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      _checkAuthentication();
      // Create a customer with a valid ID
      final newCustomerRef = _customersRef.doc();
      final customerWithId = Customer(
        id: newCustomerRef.id,
        name: customer.name,
        email: customer.email,
      );
      await newCustomerRef.set(customerWithId);
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }

  Future<(int available, int total)> availability(Book book) async {
    try {
      _checkAuthentication();
      DocumentReference<Book> bookRef = _booksRef.doc(book.id);

      final querySnapshot = await _copiesRef.where('bookRef', isEqualTo: bookRef).get();

      int total = querySnapshot.size;
      int available = querySnapshot.docs.where((doc) {
        try {
          final copy = doc.data();
          return copy.available;
        } catch (e) {
          print('Error processing copy: $e');
          return false;
        }
      }).length;

      return (available, total);
    } catch (e) {
      print('Error in availability: $e');
      return (0, 0);
    }
  }

  Future<void> borrowCopy(int customerId, int copyId) async {
    try {
      _checkAuthentication();
      final copyRef = _copiesRef.doc(copyId.toString());
      final customerRef = _customersRef.doc(customerId.toString());

      await _firestore.runTransaction((transaction) async {
        final copySnapshot = await transaction.get(copyRef);
        final customerSnapshot = await transaction.get(customerRef);

        if (!copySnapshot.exists) {
          throw Exception("Copy not found");
        }

        if (!customerSnapshot.exists) {
          throw Exception("Customer not found");
        }

        // Update the copy
        transaction.update(copyRef, {
          'available': false,
          'borrowedBy': customerId.toString(),
          'borrowDate': Timestamp.now(),
        });
      });
    } catch (e) {
      print('Error borrowing copy: $e');
      rethrow;
    }
  }

  Future<void> returnCopy(int copyId) async {
    try {
      _checkAuthentication();
      final copyRef = _copiesRef.doc(copyId.toString());

      await _firestore.runTransaction((transaction) async {
        final copySnapshot = await transaction.get(copyRef);

        if (!copySnapshot.exists) {
          throw Exception("Copy not found");
        }

        transaction.update(copyRef, {
          'available': true,
          'borrowedBy': FieldValue.delete(),
          'borrowDate': FieldValue.delete(),
          'returnDate': Timestamp.now(),
        });
      });
    } catch (e) {
      print('Error returning copy: $e');
      rethrow;
    }
  }

  Stream<List<Book>> overdueBooks() {
    try {
      _checkAuthentication();
      final now = DateTime.now();
      return _booksRef
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((error) {
            print('Error in overdueBooks: $error');
            return <Book>[];
          });
    } catch (e) {
      print('Error setting up overdueBooks stream: $e');
      return Stream.value(<Book>[]);
    }
  }

  Stream<List<Copy>> allCopies() {
    try {
      _checkAuthentication();
      return _copiesRef
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((error) {
            print('Error in allCopies: $error');
            return <Copy>[];
          });
    } catch (e) {
      print('Error setting up allCopies stream: $e');
      return Stream.value(<Copy>[]);
    }
  }

  // Add more methods with proper error handling as needed
}