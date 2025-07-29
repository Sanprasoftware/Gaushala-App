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

DateTime? _birthDate;

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cowIdController = TextEditingController();
  String? _parentId;
  List<String> _parentOptions = [];
  String? _selectedGender;
  String? _selectedAnimalType;
  List<String> _animalTypeOptions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map? _existingSupplier;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _fetchParentOptions();

    // Delay to ensure context is available
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        setState(() {
          _isEdit = true;
          _existingSupplier = args;

          _cowIdController.text = _existingSupplier!['name'] ?? '';
          _selectedAnimalType = _existingSupplier!['custom_animal_type'];
          _selectedGender = _existingSupplier!['custom_gender'];
          _parentId = _existingSupplier!['custom_supplier_parent'];
          // Birth date optional — not available from list, skip or handle separately
        });
      }
    });
  }


  Future<String?> getToken() async {
    final FlutterSecureStorage storage = FlutterSecureStorage();
    final String apiSecret = await storage.read(key: "api_secret") ?? "";
    final String apiKey = await storage.read(key: "api_key") ?? "";
    return 'token $apiKey:$apiSecret';
  }

  Future<void> _fetchParentOptions() async {
    final String? token = await getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final supplierUri = Uri.parse('https://goshala.erpkey.in/api/resource/Supplier')
          .replace(queryParameters: {'fields': jsonEncode(['name'])});
      final animalUri = Uri.parse('https://goshala.erpkey.in/api/resource/Animal%20Master')
          .replace(queryParameters: {'fields': jsonEncode(['name'])});

      final supplierRes = await http.get(supplierUri, headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      });

      final animalRes = await http.get(animalUri, headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      });

      if (supplierRes.statusCode == 200 && animalRes.statusCode == 200) {
        final supplierData = json.decode(supplierRes.body);
        final animalData = json.decode(animalRes.body);

        setState(() {
          _parentOptions = (supplierData['data'] as List).map((s) => s['name'] as String).toList();
          _animalTypeOptions = (animalData['data'] as List).map((a) => a['name'] as String).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch data')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching dropdown options')),
      );
    }
  }




  Future<void> _submitSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final String? token = await getToken();
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final supplierData = {
        'supplier_name': _cowIdController.text.trim(),
        'custom_supplier_parent': _parentId,
        'custom_gender': _selectedGender ?? '',
        'custom_animal_type': _selectedAnimalType,
        'custom_is_animal': 1,
        'custom_birth_date': _birthDate != null
            ? "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}"
            : null,
      };

      try {
        late http.Response response;

        if (_isEdit) {
          final name = _existingSupplier!['name'];
          final url = 'https://goshala.erpkey.in/api/resource/Supplier/$name';

          response = await http.put(
            Uri.parse(url),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'data': supplierData}),
          );
        } else {
          const url = 'https://goshala.erpkey.in/api/resource/Supplier';
          response = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(supplierData),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          widget.refreshSupplierList();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEdit ? 'Supplier updated successfully' : 'Supplier added successfully')),
          );
          Navigator.pop(context);
        } else {
          final responseBody = jsonDecode(response.body);
          String errorMsg = responseBody['exception'] ?? 'Operation failed';
          if (errorMsg.contains('Duplicate entry')) {
            errorMsg = 'Supplier name already exists';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
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
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFFF99)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _cowIdController,
                            readOnly: _isEdit, // <-- Make Cow ID read-only when editing
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
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedGender != '' ? _selectedGender : null,
                            hint: const Text('Select Gender'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person, color: Colors.blue[900]),
                            ),
                            items: ['Male', 'Female'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedAnimalType,
                            hint: const Text('Select Animal Type'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pets, color: Colors.blue[900]),
                            ),
                            items: _animalTypeOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAnimalType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(const Duration(days: 30)),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _birthDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Birth Date',
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[900]),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? 'Select birth date'
                                    : "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _birthDate == null ? Colors.grey[600] : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitSupplier,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              _isEdit ? 'Update Supplier' : 'Add Supplier',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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