import 'package:flutter/material.dart';
import 'package:lib_pulse/models/copy.dart';
import '/services/database_services.dart';
import '/models/book.dart';
import '/models/series.dart';
import '/models/customer.dart';
import '/screens/book_details.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  _CatalogTabState createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  bool _showCustomers = false;
  String _searchQuery = '';
  final DatabaseServices _databaseServices = DatabaseServices();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search ${_showCustomers ? 'customers' : 'books'}...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
                iconSize: 32,
                onPressed: () => _showAddDialog(context),
              ),
            ],
          ),
        ),

        // Customer/Book Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ToggleButtons(
            isSelected: [_showCustomers, !_showCustomers],
            onPressed: (index) => setState(() {
              _showCustomers = index == 0;
              _searchQuery = '';
              _searchController.clear();
            }),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Customers'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Books'),
              ),
            ],
          ),
        ),
        Container(
          height: 16,
        ),
        _showCustomers ? _buildCustomersView() : _buildBooksView(),
      ],
    );
  }

  Widget _buildCustomersView() {
    return StreamBuilder<List<Customer>>(
      stream: _databaseServices.filterCustomers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final customers = snapshot.data ?? [];
        return Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 6,
            ),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                elevation: 4,
                child: Row(
                  children: [
                    AspectRatio(
                      aspectRatio: 1 / 1,
                      child: SizedBox(
                        height: double.infinity,
                        width: double.infinity,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error),
                            Text('Image not available'),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                        ),
                        Text(
                          'Email: ${customer.email}',
                        ),
                        Text(
                          'ID: ${customer.id}',
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildCustomerActions(customer),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBooksView() {
    return StreamBuilder<List<Book>>(
      stream: _databaseServices.filterBooks(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final books = snapshot.data ?? [];
        return Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 6,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];

              return FutureBuilder<Series?>(
                future:
                    book.seriesRef?.get().then((snapshot) => snapshot.data()),
                builder: (context, seriesSnapshot) {
                  if (seriesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Card(
                      child: Text('${book.title}...'),
                    );
                  }

                  if (seriesSnapshot.hasError) {
                    return const Card(
                      child: Text('An error has occurred.'),
                    );
                  }

                  final series = seriesSnapshot.data;
                  return Card(
                    elevation: 4,
                    child: Row(
                      children: [
                        AspectRatio(
                          aspectRatio: 1 / 1,
                          child: SizedBox(
                            height: double.infinity,
                            width: double.infinity,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error),
                                Text('Image not available'),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              series != null
                                  ? 'Title: ${book.title} (${series.name} Book ${book.positionInSeries ?? ""})'
                                  : 'Title: ${book.title}',
                            ),
                            Text(
                              'by ${book.author}',
                            ),
                            Text(
                              'ISBN: ${book.isbn}',
                            ),
                            _availabilityText(book),
                          ],
                        ),
                        const Spacer(),
                        _buildBookActions(book),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _availabilityText(Book book) {
    return FutureBuilder<Map<String, int>>(
      future: _databaseServices
          .availability(book)
          .then((result) => {'available': result.$1, 'total': result.$2}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading availability...');
        }

        if (snapshot.hasError) {
          return const Text('Error loading availability');
        }

        if (!snapshot.hasData) {
          return const Text('Available: 0 / Total: 0');
        }

        return Text(
            'Available: ${snapshot.data!['available']} / Total: ${snapshot.data!['total']}');
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_showCustomers ? 'Add New Customer' : 'Add New Book'),
        content: _showCustomers
            ? AddCustomerForm(
                onSubmit: (customer) => _databaseServices.addCustomer(customer),
              )
            : AddBookForm(
                onSubmit: (book) => _databaseServices.addBook(book),
              ),
      ),
    );
  }

  Widget _buildBookActions(Book book) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'add_copy',
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 4.0),
                  child: Icon(Icons.add),
                ),
                Text('Add Copy'),
              ],
            )),
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(Icons.remove_red_eye),
              ),
              Text('View'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(Icons.delete),
              ),
              Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'add_copy') {
          _addCopy(book);
        } else if (value == 'view') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                bookRef: _databaseServices.booksRef.doc(book.id),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _addCopy(Book book) async {
    try {
      // Run on platform thread
      await Future(() async {
        final docRef = _databaseServices.copiesRef.doc();

        final newCopy = Copy(
          id: docRef.id,
          bookRef: _databaseServices.booksRef.doc(book.id),
          dateAcquired: DateTime.now(),
          available: true,
          loanRefs: [],
          reference: docRef,
        );

        await docRef.set(newCopy);
      });
    } catch (e) {
      print('Error adding copy: $e');
      rethrow;
    }
  }
}

Widget _buildCustomerActions(Customer customer) {
  return PopupMenuButton(
    itemBuilder: (context) => [
      const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(Icons.remove_red_eye),
              ),
              Text('View'),
            ],
          )),
    ],
    onSelected: (value) async {
      if (value == 'view') {
        /*
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(
                customerRef: customerRef,
              ),
            ),
          );
          */
      }
    },
  );
}

class AddBookForm extends StatefulWidget {
  final Function(Book book) onSubmit;
  const AddBookForm({super.key, required this.onSubmit});

  @override
  _AddBookFormState createState() => _AddBookFormState();
}

class _AddBookFormState extends State<AddBookForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final DatabaseServices _databaseServices = DatabaseServices();
  String? _selectedSeriesId;
  List<Series> _seriesList = [];
  int? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final series = await _databaseServices.getAllSeries();
    setState(() {
      _seriesList = series;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _isbnController,
            decoration: const InputDecoration(labelText: 'ISBN'),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Required';
              }
              if (int.tryParse(value) == null) {
                return 'ISBN must be a number';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          TextFormField(
            controller: _authorController,
            decoration: const InputDecoration(labelText: 'Author'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Series (Optional)'),
            value: _selectedSeriesId,
            items: _seriesList
                .map(
                  (series) => DropdownMenuItem<String>(
                    value: series.id,
                    child: Text(series.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSeriesId = value;
              });
            },
          ),
          TextFormField(
            // Add position input
            decoration: const InputDecoration(
                labelText: 'Position in Series (Optional)'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _selectedPosition = int.tryParse(value ?? '');
              });
            },
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'Position must be a number';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _addBook,
            child: const Text('Add Book'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBook() async {
    if (_formKey.currentState!.validate()) {
      final seriesRef = _selectedSeriesId != null
          ? _databaseServices.seriesRef.doc(_selectedSeriesId)
          : null;
      final docRef = _databaseServices.booksRef.doc();

      final newBook = Book(
        id: docRef.id,
        isbn: int.parse(_isbnController.text),
        title: _titleController.text,
        author: _authorController.text,
        seriesRef: seriesRef,
        positionInSeries: _selectedPosition,
      );

      await docRef.set(newBook);
      Navigator.pop(context);
    }
  }
}

class AddCustomerForm extends StatefulWidget {
  final Function(Customer customer) onSubmit;
  const AddCustomerForm({super.key, required this.onSubmit});

  @override
  _AddCustomerFormState createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final DatabaseServices _databaseServices = DatabaseServices();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        _databaseServices.addCustomer(
          Customer(
            id: '',
            name: _nameController.text,
            email: _emailController.text,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding customer: $e')),
        );
      }
    }
  }
}
