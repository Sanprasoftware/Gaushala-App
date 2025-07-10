import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'loginpage.dart';

class AddMaterialTransferScreen extends StatefulWidget {
  const AddMaterialTransferScreen({super.key});

  @override
  State<AddMaterialTransferScreen> createState() => _AddMaterialTransferScreenState();
}

class _AddMaterialTransferScreenState extends State<AddMaterialTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  String? sWarehouse = 'Finished Goods - SSS - G';
  String? tWarehouse;
  String? itemCode;
  String? qty;

  List<String> warehouseList = [];
  List<String> itemList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWarehouses();
    fetchItems();
  }

  Future<void> fetchWarehouses() async {
    final token = await getToken();
    const url = 'https://goshala.erpkey.in/api/resource/Warehouse';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        warehouseList = List<String>.from(data['data'].map((e) => e['name']));
      });
    }
  }

  Future<void> fetchItems() async {
    final token = await getToken();
    const url = 'https://goshala.erpkey.in/api/resource/Item?disabled=0';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        itemList = List<String>.from(data['data'].map((e) => e['name']));
      });
    }
  }

  Future<void> submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final token = await getToken();

    final body = {
      "stock_entry_type": "Material Transfer",
      "items": [
        {
          "s_warehouse": sWarehouse,
          "t_warehouse": tWarehouse,
          "item_code": itemCode,
          "qty": double.tryParse(qty!) ?? 0.0
        }
      ]
    };

    final response = await http.post(
      Uri.parse('https://goshala.erpkey.in/api/resource/Stock%20Entry'),
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material transfer submitted successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/material_transfer', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${response.body}')),
      );
    }
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
            'Add Material Transfer',
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  value: sWarehouse,
                  decoration: InputDecoration(
                    labelText: 'Source Warehouse',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.warehouse, color: Colors.blue[900]),
                  ),
                  items: warehouseList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                  onChanged: (val) => setState(() => sWarehouse = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Target Warehouse',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.move_to_inbox, color: Colors.blue[900]),
                  ),
                  items: warehouseList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                  onChanged: (val) => setState(() => tWarehouse = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Item Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code, color: Colors.blue[900]),
                  ),
                  items: itemList.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                  onChanged: (val) => setState(() => itemCode = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale, color: Colors.blue[900]),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => qty = val,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: submitTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
