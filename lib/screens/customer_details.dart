import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/services/database_services.dart';
import '/models/customer.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final DocumentReference<Customer> customerRef;
  const CustomerDetailsScreen({super.key, required this.customerRef});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final DatabaseServices _databaseServices = DatabaseServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            _infoCard(),
            _outCard(),
            _historyCard(),
          ],
        ),
      ),
    );
  }

  // customer info displayed such as name, and email (maybe eventually others as well)
  Widget _infoCard() {
    return Card(
      elevation: 3.0,
      child: StreamBuilder<DocumentSnapshot<Customer>>(
        stream: widget.customerRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Error loading customer details'),
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
              child: Text('Customer not found'),
            );
          }

          final customer = snapshot.data!.data()!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Email:', customer.email),
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

  // display using a ListView all the books that the customer currently has out (title, dueBack)
  // if overdue the item should be marked (probably using red text)
  Widget _outCard() {
    return const Card(
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Placeholder(),
      ),
    );
  }

  // display using a ListView all the Books that have been borrowed and returned by this customer
  Widget _historyCard() {
    return const Card(
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Placeholder(),
      ),
    );
  }
}
