import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'loginpage.dart';

class AddCollectionScreen extends StatefulWidget {
  const AddCollectionScreen({super.key});

  @override
  State<AddCollectionScreen> createState() => _AddCollectionScreenState();
}

class _AddCollectionScreenState extends State<AddCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate = DateTime.now(); // Default to today
  String? _selectedSupplier;
  List<String> _supplierList = [];
  final TextEditingController _qtyController = TextEditingController();
  List<String> _milkItems = [];
  String? _selectedItem;


  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _fetchMilkItems();
  }


  Future<String?> getToken() async {
    final FlutterSecureStorage storage = FlutterSecureStorage();
    final String apiSecret = await storage.read(key: "api_secret") ?? "";
    final String apiKey = await storage.read(key: "api_key") ?? "";
    return 'token $apiKey:$apiSecret';
  }


  Future<void> _fetchSuppliers() async {
    try {
      final token = await getToken();

      const apiUrl = 'https://goshala.erpkey.in/api/resource/Supplier';
      final uri = Uri.parse(apiUrl).replace(queryParameters: {
        'fields': jsonEncode(['name']),
        'filters': jsonEncode([
          ['custom_is_animal', '=', 1],
          ['custom_is_collection', '=', 1]
        ]),
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': token ?? '',
          'Content-Type': 'application/json',
        },
      );

      print('Supplier Response Status: ${response.statusCode}');
      print('Supplier Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> suppliers = data['data'] ?? [];
        setState(() {
          _supplierList = suppliers.map((s) => s['name'].toString()).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load suppliers');
      }
    } catch (e) {
      print('Supplier fetch error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch suppliers')),
      );
    }
  }


  Future<void> _fetchMilkItems() async {
    final token = await getToken();

    final uri = Uri.parse('https://goshala.erpkey.in/api/resource/Item').replace(
      queryParameters: {
        'fields': jsonEncode(['name']),
        'filters': jsonEncode([
          ['custom_is_milk', '=', 1]
        ]),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data'] as List<dynamic>;
      setState(() {
        _milkItems = items.map((item) => item['name'].toString()).toList();
        if (_milkItems.isNotEmpty) _selectedItem = _milkItems.first;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch milk items')),
      );
    }
  }


  Future<String?> _fetchWarehouse() async {
    final token = await getToken();

    final uri = Uri.parse(
        'https://goshala.erpkey.in/api/resource/Goshala Setting/Goshala Setting');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Goshala Setting: $data");
      final warehouse = data['data']['purchase_warehouse'];
      return warehouse;
    } else {
      print("Warehouse fetch failed: ${response.body}");
    }

    return null;
  }


  Future<void> _submitCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final String? itemCode = _selectedItem;
    final String? warehouse = await _fetchWarehouse();
    print("Selected item: $itemCode");
    print("Fetched warehouse: $warehouse");
    if (itemCode == null || warehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch item or warehouse')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final String supplier = _selectedSupplier!;
    final String qty = _qtyController.text.trim();

    final apiUrl = 'https://goshala.erpkey.in/api/resource/Purchase Receipt';

    final body = jsonEncode({
      'supplier': supplier,
      "docstatus": 1,
      "custom_mobile_entry":1,
      'posting_date':
      '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      'items': [
        {
          'item_code': itemCode,
          'qty': double.tryParse(qty) ?? 0,
          'warehouse': warehouse,
          'uom': 'Litre',
        }
      ]
    });

    try {
      final token = await getToken();

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': token ?? '',
          'Content-Type': 'application/json',
        },
        body: body,
      );


      print('Submit Response: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection added successfully')),
        );
        Navigator.pop(context);
      } else {
        final responseBody = jsonDecode(response.body);
        String errorMsg = responseBody['exception'] ?? 'Failed to add collection';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting collection')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 4,
        automaticallyImplyLeading: true,
        title: const Center(
          child: Text(
            'Add Collection',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFFF99)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.calendar_today, color: Colors.blue[900]),
                  ),
                  controller: TextEditingController(text: formattedDate),
                  validator: (value) {
                    if (_selectedDate == null) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedSupplier,
                  hint: const Text('Select Cow ID (Supplier)'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets, color: Colors.blue[900]),
                  ),
                  items: _supplierList.map((String supplier) {
                    return DropdownMenuItem<String>(
                      value: supplier,
                      child: Text(supplier),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSupplier = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select Cow ID';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedItem,
                  hint: const Text('Select Milk Item'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_drink, color: Colors.blue[900]),
                  ),
                  items: _milkItems.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItem = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a milk item';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Quantity (Ltr)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale, color: Colors.blue[900]),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'Add Collection',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.blue[900],
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            IconButton(
              icon: const Icon(Icons.info, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),
    );
  }
}
