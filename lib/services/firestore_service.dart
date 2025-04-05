import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Limit concurrent operations
  final int _maxConcurrentOperations = 3;
  int _currentOperations = 0;
  final List<Function> _pendingOperations = [];

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal() {
    // Set Firestore settings for better performance
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  FirebaseFirestore get firestore => _firestore;

  // Execute Firestore operations safely
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_currentOperations >= _maxConcurrentOperations) {
      // Queue the operation if too many are running
      Completer<T> completer = Completer<T>();
      _pendingOperations.add(() async {
        try {
          final result = await operation();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      });
      return completer.future;
    }

    _currentOperations++;
    try {
      return await operation();
    } finally {
      _currentOperations--;
      _processPendingOperations();
    }
  }

  void _processPendingOperations() {
    if (_pendingOperations.isNotEmpty && _currentOperations < _maxConcurrentOperations) {
      final op = _pendingOperations.removeAt(0);
      op();
    }
  }

  // Specialized methods for common Firestore operations
  Future<DocumentSnapshot<T>> getDocument<T>(DocumentReference<T> reference) {
    return execute(() => reference.get());
  }

  Future<QuerySnapshot<T>> getCollection<T>(Query<T> query) {
    return execute(() => query.get());
  }

  Stream<QuerySnapshot<T>> streamCollection<T>(Query<T> query) {
    // For streams, we wrap the stream transformation
    final streamController = StreamController<QuerySnapshot<T>>();
    
    query.snapshots().listen(
      (snapshot) {
        // Process on a separate isolate if data is large
        if (snapshot.docs.length > 20) {
          compute((_) => snapshot, null).then((processedSnapshot) {
            if (!streamController.isClosed) {
              streamController.add(processedSnapshot);
            }
          });
        } else {
          streamController.add(snapshot);
        }
      },
      onError: (error) {
        if (!streamController.isClosed) {
          streamController.addError(error);
        }
      },
      onDone: () {
        if (!streamController.isClosed) {
          streamController.close();
        }
      },
    );

    return streamController.stream;
  }

  Future<void> addDocument<T>(CollectionReference<T> collection, T data) {
    return execute(() => collection.add(data));
  }

  Future<void> setDocument<T>(DocumentReference<T> reference, T data) {
    return execute(() => reference.set(data));
  }

  Future<void> updateDocument(DocumentReference reference, Map<String, dynamic> data) {
    return execute(() => reference.update(data));
  }

  Future<void> deleteDocument(DocumentReference reference) {
    return execute(() => reference.delete());
  }

  Future<T> runTransaction<T>(Future<T> Function(Transaction) transactionFunction) {
    return execute(() => _firestore.runTransaction(transactionFunction));
  }

  Future<void> executeBatch(void Function(WriteBatch batch) batchFunction) {
    return execute(() {
      final batch = _firestore.batch();
      batchFunction(batch);
      return batch.commit();
    });
  }
}