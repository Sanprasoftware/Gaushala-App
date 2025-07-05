import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  String? _selectedSupplier;
  List<String> _suppliers = [];
  final ValueNotifier<bool> _refreshNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Set default date range to current month (July 1, 2025 to July 5, 2025)
    _fromDate = DateTime(2025, 7, 1);
    _toDate = DateTime.now();
    // _fetchSuppliers();
  }

  // Future<void> _fetchSuppliers() async {
  //   final String apiUrl = 'https://goshala.erpkey.in/api/method/frappe.client.get_list';
  //   final uri = Uri.parse(apiUrl).replace(
  //     queryParameters: {
  //       'doctype': 'Supplier',
  //       'fields': jsonEncode(['name']),
  //     },
  //   );
  //
  //   try {
  //     final response = await http.get(
  //       uri,
  //       headers: {
  //         'Authorization': 'token 22b5fcceeb021c0:353246dbfcc9d38',
  //         'X-Frappe-CSRF-Token': '8736ed027656f233b77fb3587a762737ef3e62c2cf52b5170d71b006',
  //         'Content-Type': 'application/json',
  //         'Accept': 'application/json',
  //       },
  //     );
  //
  //     print('Suppliers Response Status: ${response.statusCode}');
  //     print('Suppliers Response Body: ${response.body}');
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final List<dynamic> suppliers = data['message'] ?? [];
  //       if (mounted) {
  //         setState(() {
  //           _suppliers = suppliers.map((s) => s['name'] as String).toList();
  //         });
  //       }
  //     } else {
  //       throw Exception('Failed to fetch suppliers: ${response.statusCode} - ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Detailed Suppliers Fetch Exception: $e');
  //     if (mounted) {
  //       setState(() {
  //         _suppliers = [];
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error fetching suppliers: $e')),
  //       );
  //     }
  //   }
  // }

  Future<Map<String, dynamic>> _fetchReport() async {
    final String apiUrl = 'https://goshala.erpkey.in/api/method/frappe.desk.query_report.run';
    final uri = Uri.parse(apiUrl).replace(
      queryParameters: {
        'report_name': 'Stock Ledger', // Replace with the correct report name from your Frappe instance
        'filters': jsonEncode({
          'company': 'Goshala',
          'from_date': DateFormat('yyyy-MM-dd').format(_fromDate),
          'to_date': DateFormat('yyyy-MM-dd').format(_toDate),
          if (_selectedSupplier != null && _selectedSupplier!.isNotEmpty)
            'supplier': _selectedSupplier,
        }),
        'ignore_prepared_report': 'false',
        'are_default_filters': 'true',
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'token 22b5fcceeb021c0:353246dbfcc9d38',
          'X-Frappe-CSRF-Token': '8736ed027656f233b77fb3587a762737ef3e62c2cf52b5170d71b006',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
          'Referer': 'https://goshala.erpkey.in/app/query-report/Stock%20Ledger',
        },
      );

      print('Report Response Status: ${response.statusCode}');
      print('Report Response Headers: ${response.headers}');
      print('Report Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch report: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Detailed Report Fetch Exception: $e');
      throw Exception('Error fetching report: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _refreshNotifier.value = !_refreshNotifier.value;
      });
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
            'Reports',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'From Date',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, true),
                        ),
                      ),
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_fromDate)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'To Date',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, false),
                        ),
                      ),
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_toDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // DropdownButtonFormField<String>(
              //   value: _selectedSupplier,
              //   hint: const Text('Select Supplier (Optional)'),
              //   decoration: InputDecoration(
              //     border: OutlineInputBorder(),
              //     prefixIcon: const Icon(Icons.person),
              //   ),
              //   items: _suppliers.map((String supplier) {
              //     return DropdownMenuItem<String>(
              //       value: supplier,
              //       child: Text(supplier),
              //     );
              //   }).toList(),
              //   onChanged: (String? newValue) {
              //     if (mounted) {
              //       setState(() {
              //         _selectedSupplier = newValue;
              //         _refreshNotifier.value = !_refreshNotifier.value;
              //       });
              //     }
              //   },
              // ),
              // const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _refreshNotifier,
                  builder: (context, refresh, child) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchReport(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(fontSize: 16, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(child: Text('No data available', style: TextStyle(fontSize: 16)));
                        } else {
                          final data = snapshot.data!['message']['result'] as List<dynamic>;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Purchase Receipt')),
                                DataColumn(label: Text('Item Code')),
                                DataColumn(label: Text('Qty')),
                              ],
                              rows: data.map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(DateFormat('dd-MM-yyyy').format(DateTime.parse(item['date'])))),
                                    DataCell(Text(item['voucher_no'])),
                                    DataCell(Text(item['item_code'])),
                                    DataCell(Text(item['in_qty'].toString())),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
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