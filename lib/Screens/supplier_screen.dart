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

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    final String? token = await getToken(); // Get token from LoginPage
    print('Fetched Token: $token'); // Debug: Log the token
    const String apiUrl = 'https://goshala.erpkey.in/api/resource/Supplier?fields=["name","custom_animal_type","custom_age_months","custom_gender","custom_supplier_parent"]';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 4,
        automaticallyImplyLeading: true, // Show back arrow
        title: const Center(
          child: Text(
            'Suppliers',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.blue[900], size: 30),
            onPressed: () async {
              await Navigator.pushNamed(context, '/add_supplier');
              fetchSuppliers(); // <-- Re-fetch supplier list when back from AddSupplierScreen
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
            ? const Center(child: Text('No suppliers found'))
            : ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            final supplier = suppliers[index];
            // Try different field names to find the correct one
            String name = supplier['supplier_name'] ??
                supplier['name'] ??
                supplier['Supplier Name'] ??
                'Unknown';
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier Icon
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.store, color: Colors.blue[900], size: 30),
                    ),
                    const SizedBox(width: 12),

                    // Supplier Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Name + Animal
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  supplier['name'] ?? 'Unknown',
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

                          // Row 2: Age + Gender + Parent
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
            );



          },
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