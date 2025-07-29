import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'loginpage.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<dynamic> collections = [];
  bool isLoading = true;
  bool isDeleting = false;
  Set<String> selectedItems = {};

  @override
  void initState() {
    super.initState();
    fetchCollections();
  }

  Future<String?> getToken() async {
    const storage = FlutterSecureStorage();
    final apiKey = await storage.read(key: 'api_key') ?? '';
    final apiSecret = await storage.read(key: 'api_secret') ?? '';
    if (apiKey.isEmpty || apiSecret.isEmpty) return null;
    return 'token $apiKey:$apiSecret';
  }

  Future<void> fetchCollections() async {
    final String? token = await getToken();
    const String apiUrl =
        'https://goshala.erpkey.in/api/method/goshala_sanpra.public.py.purchase_receipt.get_purchase_receipt_items';

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
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          collections = data['message'] ?? [];
          isLoading = false;
          selectedItems.clear(); // Clear selections on refresh
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load collections: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching collections: $e')));
    }
  }

  Future<void> _cancelCollections(Set<String> names) async {
    final String? token = await getToken();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      for (String name in names) {
        final url =
            'https://goshala.erpkey.in/api/resource/Purchase Receipt/$name';
        final response = await http.put(
          Uri.parse(url),
          headers: {'Authorization': token, 'Content-Type': 'application/json'},
          body: jsonEncode({'docstatus': 2}),
        );

        if (response.statusCode != 200) {
          final error = json.decode(response.body)['message'] ?? response.body;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete collection $name: $error'),
            ),
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${names.length} collection(s) deleted successfully'),
        ),
      );
      await fetchCollections();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting collections: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
          selectedItems.clear();
        });
      }
    }
  }

  void _confirmDelete() {
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Collections'),
            content: Text(
              'Are you sure you want to delete ${selectedItems.length} selected collection(s)?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    selectedItems.clear(); // Clear selection on cancel
                  });
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _cancelCollections(selectedItems);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _toggleSelection(String parent) {
    setState(() {
      if (selectedItems.contains(parent)) {
        selectedItems.remove(parent);
      } else {
        selectedItems.add(parent);
      }
    });
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
            'Collections',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          if (selectedItems.isEmpty)
            IconButton(
              icon: Icon(Icons.add, color: Colors.blue[900], size: 30),
              onPressed: () {
                Navigator.pushNamed(context, '/add_collection');
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
              onPressed: _confirmDelete,
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
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: fetchCollections,
              child:
                  isLoading
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
                          final qty = collection['qty']?.toString() ?? '0';
                          final rate = collection['rate']?.toString() ?? '0';
                          final amount =
                              collection['amount']?.toString() ?? '0';
                          final isSelected = selectedItems.contains(parent);

                          return GestureDetector(
                            onLongPress: () => _toggleSelection(parent),
                            child: Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color:
                                  isSelected
                                      ? Colors.blue[100]!.withOpacity(0.95)
                                      : Colors.white.withOpacity(0.95),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "🧾 $parent",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "🐄 $itemCode",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                "📦 $qty",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                "💰 ₹$rate",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                "🧮 ₹$amount",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            if (isDeleting)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
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
