import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/services/database_services.dart';
import '/models/book.dart';

class BookDetailsScreen extends StatefulWidget {
  final DocumentReference<Book> bookRef;
  const BookDetailsScreen({
    super.key,
    required this.bookRef,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final DatabaseServices _databaseServices = DatabaseServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            _coverCard(),
            _infoCard(),
            _copiesCard(),
            _seriesCard(),
          ],
        ),
      ),
    );
  }

  // display an image of the cover of the book
  Widget _coverCard() {
    return const Card(
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Placeholder(),
      ),
    );
  }

  // display a ListView of all the books in the series for the book, as well as their positions, the current book should have bold text, or some other styling to make it stand out
  Widget _seriesCard() {
    return const Card(
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Placeholder(),
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      elevation: 3.0,
      child: StreamBuilder<DocumentSnapshot<Book>>(
        stream: widget.bookRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Error loading book details'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Book not found'),
            );
          }

          final book = snapshot.data!.data()!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Author:', book.author),
                _buildInfoRow('ISBN:', book.isbn.toString()),
                if (book.genres.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Genres:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: book.genres
                        .map((genre) => Chip(
                              label: Text(genre),
                              visualDensity: const VisualDensity(
                                  horizontal: 0, vertical: -4),
                            ))
                        .toList(),
                  ),
                ],
                if (book.seriesRef != null &&
                    book.positionInSeries != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Series Position:',
                    '#${book.positionInSeries}',
                  ),
                ],
                if (book.readingTimes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Avg. Checkout Time:',
                    _calculateAverageReadingTime(book.readingTimes),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _calculateAverageReadingTime(List<Duration> readingTimes) {
    final totalDuration = readingTimes.fold<Duration>(
      Duration.zero,
      (prev, element) => prev + element,
    );
    final average = totalDuration ~/ readingTimes.length;

    final hours = average.inHours;
    final minutes = average.inMinutes.remainder(60);

    final parts = [];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');

    return parts.isEmpty ? 'Less than a minute' : parts.join(' ');
  }

  // display a ListView of all of the copies of the book and their statuses as being borrowed, available, dueBack, borrowed by whom, etc.
  Widget _copiesCard() {
    return const Card(
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Placeholder(),
      ),
    );
  }
}
