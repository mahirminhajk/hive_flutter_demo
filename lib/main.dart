import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('myBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hive CRUD Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _refreshItem();
  }

  //* reference to the box
  final _myBox = Hive.box('myBox');

  //* refreshItems
  void _refreshItem() {
    final data = _myBox.keys.map((key) {
      final item = _myBox.get(key);
      return {"key": key, "name": item["name"], "quantity": item["quantity"]};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      print(_items);
    });
  }

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _myBox.add(newItem);
    _refreshItem();
  }

  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _myBox.put(itemKey, item);
    _refreshItem();
  }

  Future<void> _deleteItem(int itemKey) async {
    await _myBox.delete(itemKey);
    _refreshItem();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('An item has been deleted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showForm(BuildContext ctx, int? itemKey) async {
    if (itemKey != null) {
      final item = _myBox.get(itemKey);
      _nameController.text = item['name'];
      _quantityController.text = item['quantity'].toString();
    }

    showModalBottomSheet(
      context: ctx,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Quantity',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (itemKey != null) {
                  await _updateItem(itemKey, {
                    'name': _nameController.text,
                    'quantity': int.parse(_quantityController.text),
                  });
                } else {
                  await _createItem({
                    'name': _nameController.text,
                    'quantity': int.parse(_quantityController.text),
                  });
                }

                //* clear the text fields
                _nameController.clear();
                _quantityController.clear();
                //* close the bottom sheet
                Navigator.of(context).pop();
              },
              child: Text(
                itemKey != null ? 'Update' : 'Create new',
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive CRUD Demo'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, index) {
          final currentItem = _items[index];
          return Card(
            color: Colors.orange.shade100,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(currentItem['name']),
              subtitle: Text(currentItem['quantity'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showForm(context, currentItem['key']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteItem(currentItem['key']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
