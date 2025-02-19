import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lib_pulse/models/book.dart';

class Series {
  final String id;
  final String name;
  final List<int> positions;
  final List<DocumentReference<Book>> booksRef;

  Series({
    required this.id,
    required this.name,
    required this.positions,
    this.booksRef = const [],
  });

  void addBook(int position, DocumentReference<Book> bookRef) {
    positions.add(position);
    booksRef.add(bookRef);
  }

  Series.fromJson(Map<String, Object?> json)
      : id = json['id'] as String, // Read ID
        name = json['name'] as String,
        positions = List<int>.from((json['positions'] as List?) ?? []),
        booksRef = (json['booksRef'] as List?)
                ?.map((ref) => ref as DocumentReference<Book>)
                .toList() ??
            [];

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'positions': positions,
      'booksRef': booksRef,
    };
  }
}
