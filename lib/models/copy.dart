import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/book.dart';
import '/models/loan.dart';

class Copy {
  final String id;
  final DocumentReference<Book> bookRef;
  final DateTime dateAcquired;
  final bool available;
  final List<DocumentReference<Loan>> loanRefs;
  final DocumentReference<Copy> reference;

  Copy({
    required this.id,
    required this.bookRef,
    required this.dateAcquired,
    this.available = true,
    this.loanRefs = const [],
    required this.reference,
  });

  Copy.fromJson(Map<String, Object?> json, {required this.reference})
      : id = json['id'] as String,
        bookRef = json['bookRef'] as DocumentReference<Book>,
        dateAcquired = (json['dateAcquired'] as Timestamp).toDate(),
        available = json['available'] as bool,
        loanRefs = (json['loanRefs'] as List?)?.map((ref) => ref as DocumentReference<Loan>).toList() ?? [];

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'bookRef': bookRef,
      'dateAcquired': Timestamp.fromDate(dateAcquired),  // Changed to Timestamp
      'available': available,
      'loanRefs': loanRefs,
    };
  }

  
}