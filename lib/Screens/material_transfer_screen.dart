import 'package:flutter/material.dart';
import 'package:gaushala/Screens/add_material_transfer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MaterialTransferScreen extends StatefulWidget {
  const MaterialTransferScreen({super.key});

  @override
  State<MaterialTransferScreen> createState() => _MaterialTransferScreenState();
}

class _MaterialTransferScreenState extends State<MaterialTransferScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> materialTransfers = [];
  bool isLoading = true;
  bool selectionMode = false;
  Set<String> selectedNames = {};


  @override
  void initState() {
    super.initState();
    fetchMaterialTransfers();
  }

  Future<void> fetchMaterialTransfers() async {
    final String? apiKey = await _storage.read(key: "api_key");
    final String? apiSecret = await _storage.read(key: "api_secret");
    const String apiUrl = 'https://goshala.erpkey.in/api/resource/Stock%20Entry?fields=["name","posting_date"]&filters=[["purpose","=","Material Transfer"]]';

    if (apiKey == null || apiSecret == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'token $apiKey:$apiSecret',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transfers = data['data'] ?? [];

        List<Map<String, dynamic>> detailedTransfers = [];

        for (var transfer in transfers) {
          final name = transfer['name'];
          final detailUrl = 'https://goshala.erpkey.in/api/resource/Stock%20Entry/$name';

          final detailResponse = await http.get(
            Uri.parse(detailUrl),
            headers: {
              'Authorization': 'token $apiKey:$apiSecret',
              'Content-Type': 'application/json',
            },
          );

          if (detailResponse.statusCode == 200) {
            final detailData = json.decode(detailResponse.body);
            detailedTransfers.add(detailData['data']);
          }
        }

        setState(() {
          materialTransfers = detailedTransfers;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching material transfers')),
      );
    }
  }

  Future<void> deleteSelectedEntries() async {
    final String? apiKey = await _storage.read(key: "api_key");
    final String? apiSecret = await _storage.read(key: "api_secret");

    if (apiKey == null || apiSecret == null) return;

    List<Future<http.Response>> deleteRequests = [];

    for (String name in selectedNames) {
      final deleteUrl = 'https://goshala.erpkey.in/api/resource/Stock%20Entry/$name';
      deleteRequests.add(
        http.delete(
          Uri.parse(deleteUrl),
          headers: {
            'Authorization': 'token $apiKey:$apiSecret',
            'Content-Type': 'application/json',
          },
        ),
      );
    }

    // Wait for all DELETE requests to finish
    await Future.wait(deleteRequests);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted selected material transfers')),
    );

    // Clear selection and refresh
    setState(() {
      selectionMode = false;
      selectedNames.clear();
    });

    await fetchMaterialTransfers();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 4,
        title: Center(
          child: Text(
            selectionMode
                ? '${selectedNames.length} selected'
                : 'Material Transfers',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (selectionMode)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[800]),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text('Are you sure you want to delete the selected entries?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), // Cancel
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), // Confirm
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await deleteSelectedEntries(); // Only call delete if confirmed
                  }
                }

            )
          else
            IconButton(
              icon: Icon(Icons.add, color: Colors.blue[900], size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMaterialTransferScreen()),
                ).then((_) => fetchMaterialTransfers());
              },
            ),
        ],
        leading: selectionMode
            ? IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            setState(() {
              selectionMode = false;
              selectedNames.clear();
            });
          },
        )
            : null,
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
            : materialTransfers.isEmpty
            ? const Center(child: Text('No material transfers found'))
            : ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: materialTransfers.length,
          itemBuilder: (context, index) {
            final transfer = materialTransfers[index];
            final name = transfer['name'] ?? 'Unknown';
            final postingDate = transfer['posting_date'] ?? '-';

            final items = transfer['items'] ?? [];
            final item = items.isNotEmpty ? items[0] : null;

            bool isSelected = selectedNames.contains(name);

            return GestureDetector(
              onLongPress: () {
                setState(() {
                  selectionMode = true;
                  selectedNames.add(name);
                });
              },
              onTap: () {
                if (selectionMode) {
                  setState(() {
                    if (isSelected) {
                      selectedNames.remove(name);
                      if (selectedNames.isEmpty) selectionMode = false;
                    } else {
                      selectedNames.add(name);
                    }
                  });
                }
              },
              child: Opacity(
                opacity: isSelected ? 0.5 : 1,
                child: Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isSelected ? Colors.blue[100] : Colors.white.withOpacity(0.95),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? Colors.red : Colors.blue[900]!,
                          width: 5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                        ),
                        const SizedBox(height: 8),
                        if (item != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("📅 $postingDate", style: const TextStyle(fontSize: 13.5)),
                              Text("🔢 ${item['item_code']}", style: const TextStyle(fontSize: 13.5)),
                              Text("📦 Qty: ${item['qty']}", style: const TextStyle(fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text("From: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              Expanded(child: Text(item['s_warehouse'] ?? '', style: const TextStyle(fontSize: 13.5))),
                            ],
                          ),
                          Row(
                            children: [
                              const Text("To: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              Expanded(child: Text(item['t_warehouse'] ?? '', style: const TextStyle(fontSize: 13.5))),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
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
