import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'loginpage.dart'; // Import LoginPage to use getToken

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<dynamic> collections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollections();
  }

  Future<void> fetchCollections() async {
    final String? token = await getToken(); // Get token from LoginPage
    const String apiUrl = 'https://goshala.erpkey.in/api/resource/Purchase%20Receipt?fields=["name","posting_date"]&order_by=posting_date desc';

    if (token == null || token.isEmpty) {
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
          collections = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load collections: ${response.body}')),
        );
      }
    } catch (e) {
      print('Exception Caught: $e'); // Debug: Log exception details
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching collections')),
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
            'Collections',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.blue[900], size: 30),
            onPressed: () {
              Navigator.pushNamed(context, '/add_collection');
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
            : collections.isEmpty
            ? const Center(child: Text('No collections found'))
            : ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            // Try different field names to find the correct one for Purchase Receipt
            String name = collection['name'] ?? collection['purchase_receipt_no'] ?? 'Unknown';
            String date = collection['posting_date'] ?? collection['transaction_date'] ?? 'N/A';
            // String amount = collection['grand_total']?.toString() ?? 'N/A';
            return Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue[900]!.withOpacity(0.3), width: 1),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: $date', style: const TextStyle(color: Colors.black54)),
                    // Text('Amount: ₹$amount', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                leading: Icon(Icons.receipt, color: Colors.blue[900]),
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