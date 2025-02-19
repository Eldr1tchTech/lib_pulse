import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/series.dart';

class Book {
  final String id;
  final int isbn;
  final String title;
  final String author;
  final List<String> genres;
  final List<Duration> readingTimes;
  final DocumentReference<Series>? seriesRef;
  final int? positionInSeries;

  Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.genres = const [],
    this.readingTimes = const [],
    required this.seriesRef,
    required this.positionInSeries,
  });

  Book.fromJson(Map<String, Object?> json)
      : id = json['id'] as String,
        isbn = json['isbn'] as int,
        title = json['title'] as String,
        author = json['author'] as String,
        genres = List<String>.from((json['genres'] as List?) ?? []),
        readingTimes = (json['readingTimes'] as List?)
                ?.map((e) => Duration(minutes: e as int))
                .toList() ??
            [],
        seriesRef = json['seriesRef'] as DocumentReference<Series>?,
        positionInSeries = json['positionInSeries'] as int?;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'author': author,
      'genres': genres,
      'readingTimes': readingTimes.map((e) => e.inMinutes).toList(),
      'seriesRef': seriesRef,
      'positionInSeries': positionInSeries,
    };
  }
}
