import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'loginpage.dart'; // Import LoginPage to use getToken

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<dynamic> suppliers = [];
  bool isLoading = true;
  List<String> selectedSuppliers = [];
  bool isSelectionMode = false;


  @override
  void initState() {
    super.initState();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    final String? token = await getToken(); // Get token from LoginPage
    print('Fetched Token: $token'); // Debug: Log the token
    const String apiUrl = 'https://goshala.erpkey.in/api/resource/Supplier?fields=["name","custom_animal_type","custom_age_months","custom_gender","custom_supplier_parent"]&limit=1000&order_by=creation desc';
    if (token == null || token.isEmpty) {
      print('Error: Token is null or empty'); // Debug: Log token issue
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );
      print('API Response Status: ${response.statusCode}'); // Debug: Log status code
      print('API Response Body: ${response.body}'); // Debug: Log full response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed Data: $data'); // Debug: Log parsed JSON
        setState(() {
          suppliers = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load suppliers: ${response.body}')),
        );
      }
    } catch (e) {
      print('Exception Caught: $e'); // Debug: Log exception details
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching suppliers')),
      );
    }
  }

  Future<void> deleteSelectedSuppliers() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;

    for (final supplierName in selectedSuppliers) {
      final deleteUrl = 'https://goshala.erpkey.in/api/resource/Supplier/$supplierName';
      try {
        final response = await http.delete(
          Uri.parse(deleteUrl),
          headers: {
            'Authorization': '$token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          print('Deleted: $supplierName');
        } else {
          print('Failed to delete $supplierName: ${response.body}');
        }
      } catch (e) {
        print('Error deleting $supplierName: $e');
      }
    }

    selectedSuppliers.clear();
    isSelectionMode = false;
    await fetchSuppliers();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 4,
        automaticallyImplyLeading: true,
        title: Center(
          child: Text(
            isSelectionMode ? 'Select Cow' : 'Cow',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 28),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete the selected suppliers?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                    ],
                  ),
                );

                if (confirm == true) {
                  await deleteSelectedSuppliers();
                }
              },
            )
          else
            IconButton(
              icon: Icon(Icons.add, color: Colors.blue[900], size: 30),
              onPressed: () async {
                await Navigator.pushNamed(context, '/add_supplier');
                fetchSuppliers();
              },
            ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFFF99)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : suppliers.isEmpty
            ? const Center(child: Text('No Cow found'))
            : ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              final supplierName = supplier['name'] ?? 'Unknown';
              final isSelected = selectedSuppliers.contains(supplierName);

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    isSelectionMode = true;
                    selectedSuppliers.add(supplierName);
                  });
                },
                onTap: () {
                  if (isSelectionMode) {
                    setState(() {
                      if (isSelected) {
                        selectedSuppliers.remove(supplierName);
                        if (selectedSuppliers.isEmpty) isSelectionMode = false;
                      } else {
                        selectedSuppliers.add(supplierName);
                      }
                    });
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/add_supplier',
                      arguments: supplier, // supplier is the current item from API
                    ).then((_) {
                      fetchSuppliers(); // Refresh list when you come back
                    });
                  }
                },
                child: Card(
                  color: isSelected ? Colors.blue[100] : Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.store, color: Colors.blue[900], size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Name + Animal
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      supplierName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (supplier['custom_animal_type'] != null)
                                    Expanded(
                                      child: Text(
                                        "🐄 ${supplier['custom_animal_type']}",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (supplier['custom_age_months'] != null)
                                    Flexible(
                                      child: Text(
                                        "📆 ${supplier['custom_age_months']}",
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ),
                                  if (supplier['custom_gender'] != null)
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          "⚥ ${supplier['custom_gender']}",
                                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                      ),
                                    ),
                                  if (supplier['custom_supplier_parent'] != null)
                                    Flexible(
                                      child: Text(
                                        "👤 ${supplier['custom_supplier_parent']}",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
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