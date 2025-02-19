import 'package:flutter/material.dart';
import 'package:lib_pulse/services/database_services.dart';
import '/pages/dashboard.dart';
import '/screens/settings.dart';
import '/pages/catalog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseServices databaseServices = DatabaseServices();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('School Book Catalog'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Catalog'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DashboardTab(),
            CatalogTab(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                heroTag: 'fabBorrow',
                onPressed: () => _showBorrowDialog(context),
                child: const Icon(Icons.remove),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                heroTag: 'fabReturn',
                onPressed: () => _showReturnDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBorrowDialog(BuildContext context) {
  final customerIdController = TextEditingController();
  final copyIdController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Borrow Book'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: customerIdController,
              decoration: const InputDecoration(
                labelText: 'Customer ID',
                hintText: 'Enter customer ID',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the customer ID';
                }
                if (databaseServices.hasCustomer(int.parse(value)) == false) {
                  return 'Customer not found';
                }
                return null;
              },
            ),
            TextFormField(
              controller: copyIdController,
              decoration: const InputDecoration(
                labelText: 'Book Copy ID',
                hintText: 'Enter copy ID',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the book copy ID';
                }
                if (databaseServices.hasCopy(int.parse(value)) == false) {
                  return 'Copy not found';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              databaseServices.borrowCopy(
                int.parse(customerIdController.text),
                int.parse(copyIdController.text),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}


  void _showReturnDialog(BuildContext context) {
    final copyIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Book'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: copyIdController,
            decoration: const InputDecoration(
              labelText: 'Book Copy ID',
              hintText: 'Enter copy ID',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a valid copy ID';
              }
              if (databaseServices.hasCopy(int.parse(value)) == false) {
                return 'Copy not found';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                databaseServices.returnCopy(int.parse(copyIdController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
