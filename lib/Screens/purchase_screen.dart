import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'loginpage.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<dynamic> collections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCollections();
  }

  Future<void> fetchCollections() async {
    final String? token = await getToken();
    const String apiUrl =
        'https://goshala.erpkey.in/api/method/goshala_sanpra.public.py.purchase_receipt.get_purchase_receipt_items_exclude_cow';

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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> dataList = data['message'] ?? [];

        setState(() {
          collections = dataList;
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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching collections')),
      );
    }
  }



  Future<void> _cancelCollection(String name) async {
    final String? token = await getToken();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    final url = 'https://goshala.erpkey.in/api/resource/Purchase Receipt/$name';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'docstatus': 2}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection Deleted successfully')),
        );
        fetchCollections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel collection: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }



  void _confirmDelete(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection'),
        content: const Text('Are you sure you want to delete this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelCollection(name);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
            'Purchase',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.blue[900], size: 30),
            onPressed: () {
              Navigator.pushNamed(context, '/add_purchase');
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

              final parent = collection['parent'] ?? 'N/A';
              final itemCode = collection['item_code'] ?? 'N/A';
              final qty = (collection['qty'] ?? 0).toString();
              final rate = (collection['rate'] ?? 0).toString();
              final amount = (collection['amount'] ?? 0).toString();

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: Colors.blue[900]!,
                        width: 5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Parent (Header)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            parent,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[700]),
                            onPressed: () => _confirmDelete(parent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Line 2: item_code + qty
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("🧾 $itemCode", style: const TextStyle(fontSize: 13.5)),
                          Text("📦 Qty: $qty", style: const TextStyle(fontSize: 13.5)),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Line 3: rate + amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("💰 Rate: ₹$rate", style: const TextStyle(fontSize: 13.5)),
                          Text("🧮 Amt: ₹$amount", style: const TextStyle(fontSize: 13.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          )

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
