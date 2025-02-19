import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '/services/database_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/book.dart';
import '/models/series.dart';
import '/models/copy.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final DatabaseServices _databaseServices = DatabaseServices();

  @override
  Widget build(BuildContext context) {
    print('building catalog');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.5,
          children: [
            _buildOverdue(),
            _buildActivityStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdue() {
    return Card(
      elevation: 3,
      child: StreamBuilder<List<Book>>(
        stream: _databaseServices.overdueBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No overdue books'));
          }

          final overdueBooks = snapshot.data!;
          return ListView.builder(
            itemCount: overdueBooks.length,
            itemBuilder: (context, index) {
              final book = overdueBooks[index];
              return FutureBuilder<Series?>(
                future:
                    book.seriesRef?.get().then((snapshot) => snapshot.data()),
                builder: (context, seriesSnapshot) {
                  String title = book.title;
                  if (seriesSnapshot.hasData && seriesSnapshot.data != null) {
                    final series = seriesSnapshot.data!;
                    title =
                        '${book.title} (${series.name} Book ${book.positionInSeries ?? ""})';
                  }

                  return ListTile(
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('by ${book.author}'),
                        Text('ISBN: ${book.isbn}'),
                        // Add due date and other relevant information
                        // Example:
                        // Text('Due Date: ${book.dueDate.toString()}'),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityStats() {
    return StreamBuilder<List<Copy>>(
      stream: _databaseServices.allCopies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(child: Text('No copies found'));
        }

        final copies = snapshot.data!;
        List<FlSpot> spots = [];
        Map<double, double> activity = {};

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Activity Distribution over Day",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),),
                const SizedBox(height: 8),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: StreamBuilder<List<Copy>>(
                        // Rebuild when copies change
                        stream: _databaseServices.allCopies(),
                        builder: (context, copiesSnapshot) {
                          if (!copiesSnapshot.hasData ||
                              copiesSnapshot.data == null) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final copies = copiesSnapshot.data!;

                          return ListView.builder(
                            itemCount: copies.length,
                            itemBuilder: (context, index) {
                              final copy = copies[index];

                              return StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: copy.reference
                                    .collection('loanHistory')
                                    .snapshots(),
                                builder: (context, loanSnapshot) {
                                  if (loanSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox.shrink();
                                  }

                                  if (loanSnapshot.hasError) {
                                    return Text('Error: ${loanSnapshot.error}');
                                  }

                                  if (!loanSnapshot.hasData ||
                                      loanSnapshot.data == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final loanRecords = loanSnapshot.data!.docs;

                                  for (final loanDoc in loanRecords) {
                                    final loanData = loanDoc.data();
                                    final borrowDate =
                                        (loanData['dateOut'] as Timestamp)
                                            .toDate();
                                    final returnDateTimestamp =
                                        loanData['dateIn'] as Timestamp?;

                                    if (!loanData['isRenewal']) {
                                      activity[borrowDate.hour.toDouble()] =
                                          (activity[borrowDate.hour
                                                      .toDouble()] ??
                                                  0) +
                                              1;
                                      if (returnDateTimestamp != null) {
                                        final returnDate =
                                            returnDateTimestamp.toDate();
                                        activity[returnDate.hour.toDouble()] =
                                            (activity[returnDate.hour
                                                        .toDouble()] ??
                                                    0) +
                                                1;
                                      }
                                    }
                                  }

                                  Map<double, double> sortActivityByTime(
                                      Map<double, double> activity) {
                                    var sortedEntries = activity.entries
                                        .toList()
                                      ..sort((a, b) => a.key.compareTo(b.key));

                                    return Map.fromEntries(sortedEntries);
                                  }

                                  activity = sortActivityByTime(activity);

                                  activity.forEach((hour, count) {
                                    spots.add(FlSpot(hour, count));
                                  });

                                  return LineChart(
                                    LineChartData(
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: spots,
                                          isCurved: true,
                                          preventCurveOverShooting: true,
                                          barWidth: 4,
                                          belowBarData:
                                              BarAreaData(show: false),
                                          dotData: const FlDotData(show: false),
                                        ),
                                      ],
                                      titlesData: const FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                          ),
                                          axisNameWidget: Text('Actions'),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true, interval: 1),
                                          axisNameWidget: Text('Time of Day'),
                                        ),
                                      ),
                                      gridData: const FlGridData(show: false),
                                      borderData: FlBorderData(show: true),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
