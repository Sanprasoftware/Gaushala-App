import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'loginpage.dart';

class AddSupplierScreen extends StatefulWidget {
  final Function refreshSupplierList;

  const AddSupplierScreen({super.key, required this.refreshSupplierList});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cowIdController = TextEditingController();
  String? _parentId;
  List<String> _parentOptions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchParentOptions();
  }

  Future<void> _fetchParentOptions() async {
    final String? token = await getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      const String apiUrl = 'https://goshala.erpkey.in/api/resource/Supplier';
      final uri = Uri.parse(apiUrl).replace(
        queryParameters: {
          'fields': jsonEncode(['name']),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'token 22b5fcceeb021c0:353246dbfcc9d38', // 👈 Hardcoded just for demo, ideally use `token`
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> suppliers = data['data'] ?? [];
        setState(() {
          _parentOptions = suppliers.map((s) => s['name'] as String).toList();
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch parent options')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _addSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final String? token = await getToken(); // e.g. "22b5fcceeb021c0:474c875b6ca3f6c"

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      try {
        const String apiUrl = 'https://goshala.erpkey.in/api/resource/Supplier';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'token 22b5fcceeb021c0:353246dbfcc9d38',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'supplier_name': _cowIdController.text.trim(),
            'custom_supplier_parent': _parentId,
          }),
        );

        print('Add Supplier Response Status: ${response.statusCode}');
        print('Add Supplier Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          widget.refreshSupplierList();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier added successfully')),
          );
          _cowIdController.clear();
          setState(() {
            _parentId = null;
          });
          Navigator.pop(context);
        } else {
          final responseBody = jsonDecode(response.body);
          String errorMsg = responseBody['exception'] ?? 'Failed to add supplier';
          if (errorMsg.contains('Duplicate entry')) {
            errorMsg = 'Supplier name already registered';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } catch (e) {
        print('Exception Caught: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding supplier')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cowIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 4,
        automaticallyImplyLeading: true,
        title: const Center(
          child: Text(
            'Add Supplier',
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
                  controller: _cowIdController,
                  decoration: InputDecoration(
                    labelText: 'Cow ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_dining, color: Colors.blue[900]),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Cow ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _parentId,
                  hint: Text('Select Parent ID (Optional)'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link, color: Colors.blue[900]),
                  ),
                  items: _parentOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _parentId = newValue;
                    });
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _addSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'Add Supplier',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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