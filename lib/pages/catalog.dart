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
  bool _isLoading = false;
  String? _errorMessage;

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
            isSelected: [!_showCustomers, _showCustomers],
            onPressed: (index) => setState(() {
              _showCustomers = index == 1;
              _searchQuery = '';
              _searchController.clear();
            }),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Books'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Customers'),
              ),
            ],
          ),
        ),
        
        // Show error message if any
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          
        Container(height: 16),
        
        // Show loading indicator if loading
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          _showCustomers ? _buildCustomersView() : _buildBooksView(),
      ],
    );
  }

  Widget _buildCustomersView() {
    return StreamBuilder<List<Customer>>(
      stream: _databaseServices.filterCustomers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final customers = snapshot.data ?? [];
        
        if (customers.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text('No customers found'),
            ),
          );
        }
        
        return Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name[0].toUpperCase()),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.email),
                  trailing: _buildCustomerActions(customer),
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
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final books = snapshot.data ?? [];
        
        if (books.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text('No books found'),
            ),
          );
        }
        
        return Expanded(
          child: ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.book, size: 40),
                  title: Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('by ${book.author}'),
                      Text('ISBN: ${book.isbn}'),
                      FutureBuilder<Map<String, int>>(
                        future: _databaseServices
                            .availability(book)
                            .then((result) => {
                                  'available': result.$1,
                                  'total': result.$2
                                })
                            .catchError((e) => {'available': 0, 'total': 0}),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading availability...');
                          }

                          final data = snapshot.data ?? {'available': 0, 'total': 0};
                          return Text(
                              'Available: ${data['available']} / Total: ${data['total']}');
                        },
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: _buildBookActions(book),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailsScreen(
                          bookRef: _databaseServices.booksRef.doc(book.id),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBookActions(Book book) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add_copy',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.add),
              ),
              Text('Add Copy'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.remove_red_eye),
              ),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.delete),
              ),
              Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        try {
          if (value == 'add_copy') {
            await _addCopy(book);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copy added successfully')),
            );
          } else if (value == 'view') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsScreen(
                  bookRef: _databaseServices.booksRef.doc(book.id),
                ),
              ),
            );
          } else if (value == 'delete') {
            // Add delete confirmation dialog
            _showDeleteConfirmationDialog(book);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      },
    );
  }

  void _showDeleteConfirmationDialog(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Delete the book
              try {
                _databaseServices.deleteBook(book.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting book: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCopy(Book book) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
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
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error adding copy: $e';
      });
      print('Error adding copy: $e');
      rethrow;
    }
  }

  Widget _buildCustomerActions(Customer customer) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.remove_red_eye),
              ),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.edit),
              ),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.delete),
              ),
              Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'view') {
          // Implement view customer details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View customer details - Coming soon')),
          );
        } else if (value == 'edit') {
          // Implement edit customer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit customer - Coming soon')),
          );
        } else if (value == 'delete') {
          // Implement delete customer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delete customer - Coming soon')),
          );
        }
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
}

// Keep the existing AddBookForm and AddCustomerForm classes...
// Include the rest of the file here

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
