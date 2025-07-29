import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'loginpage.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  DateTime? _selectedDate = DateTime.now();
  String? _selectedCustomer;
  List<String> _customerList = [];
  List<String> _itemList = [];
  List<String> _uomList = [];
  List<String> _warehouseList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // List to store multiple items with GlobalKeys for scrolling
  final List<Map<String, dynamic>> _items = [
    {
      'qtyController': TextEditingController(),
      'rateController': TextEditingController(),
      'amountController': TextEditingController(),
      'selectedItem': null,
      'selectedUom': null,
      'selectedWarehouse': 'Finished Goods - SSS - G', // Default warehouse
      'itemKey': GlobalKey(),
      'uomKey': GlobalKey(),
      'warehouseKey': GlobalKey(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchItems();
    _fetchUOMs();
    _fetchWarehouses();
    for (var item in _items) {
      (item['qtyController'] as TextEditingController).addListener(
        () => _calculateAmount(item),
      );
      (item['rateController'] as TextEditingController).addListener(
        () => _calculateAmount(item),
      );
    }
  }

  void _calculateAmount(Map<String, dynamic> item) {
    final qty = double.tryParse(item['qtyController'].text) ?? 0;
    final rate = double.tryParse(item['rateController'].text) ?? 0;
    final amount = qty * rate;
    item['amountController'].text = amount.toStringAsFixed(2);
    if (mounted) setState(() {});
  }

  Future<String?> getToken() async {
    const storage = FlutterSecureStorage();
    final String apiSecret = await storage.read(key: "api_secret") ?? "";
    final String apiKey = await storage.read(key: "api_key") ?? "";
    if (apiKey.isEmpty || apiSecret.isEmpty) {
      print('Token error: Empty api_key or api_secret');
      return null;
    }
    return 'token $apiKey:$apiSecret';
  }

  Future<void> _fetchCustomers() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');
      final uri = Uri.parse(
        'https://goshala.erpkey.in/api/resource/Customer',
      ).replace(
        queryParameters: {
          'fields': jsonEncode(['name']),
          'limit_page_length': '100',
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> customers = data['data'] ?? [];
        if (mounted) {
          setState(() {
            _customerList = customers.map((c) => c['name'].toString()).toList();
            print('Fetched customers: $_customerList');
            _isLoading = false;
          });
        }
      } else {
        throw Exception(
          'Failed to load customers: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Customer fetch error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch customers')),
        );
      }
    }
  }

  Future<void> _fetchItems() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');
      final uri = Uri.parse(
        'https://goshala.erpkey.in/api/resource/Item',
      ).replace(
        queryParameters: {
          'fields': jsonEncode(['item_code']),
          'limit_page_length': '100',
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['data'] ?? [];
        if (mounted) {
          setState(() {
            _itemList = items.map((i) => i['item_code'].toString()).toList();
            print('Fetched items: $_itemList');
          });
        }
      } else {
        throw Exception(
          'Failed to load items: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Item fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to fetch items')));
      }
    }
  }

  Future<void> _fetchUOMs() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');
      final uri = Uri.parse(
        'https://goshala.erpkey.in/api/resource/UOM',
      ).replace(
        queryParameters: {
          'fields': jsonEncode(['name']),
          'limit_page_length': '100',
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> uoms = data['data'] ?? [];
        if (mounted) {
          setState(() {
            _uomList = uoms.map((u) => u['name'].toString()).toList();
            print('Fetched UOMs: $_uomList');
          });
        }
      } else {
        throw Exception(
          'Failed to load UOMs: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('UOM fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to fetch UOMs')));
      }
    }
  }

  Future<void> _fetchWarehouses() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');
      final uri = Uri.parse(
        'https://goshala.erpkey.in/api/resource/Warehouse',
      ).replace(
        queryParameters: {
          'fields': jsonEncode(['name']),
          'limit_page_length': '100',
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> warehouses = data['data'] ?? [];
        if (mounted) {
          setState(() {
            _warehouseList =
                warehouses.map((w) => w['name'].toString()).toList();
            print('Fetched warehouses: $_warehouseList');
          });
        }
      } else {
        throw Exception(
          'Failed to load warehouses: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Warehouse fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch warehouses')),
        );
      }
    }
  }

  void _addItem() {
    setState(() {
      final newItem = {
        'qtyController': TextEditingController(),
        'rateController': TextEditingController(),
        'amountController': TextEditingController(),
        'selectedItem': null,
        'selectedUom': null,
        'selectedWarehouse': 'Finished Goods - SSS - G', // Default warehouse
        'itemKey': GlobalKey(),
        'uomKey': GlobalKey(),
        'warehouseKey': GlobalKey(),
      };
      (newItem['qtyController'] as TextEditingController).addListener(
        () => _calculateAmount(newItem),
      );
      (newItem['rateController'] as TextEditingController).addListener(
        () => _calculateAmount(newItem),
      );
      _items.add(newItem);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index]['qtyController'].dispose();
      _items[index]['rateController'].dispose();
      _items[index]['amountController'].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submitDelivery() async {
    print('Starting submission...');
    print('Date: $_selectedDate');
    print('Customer: $_selectedCustomer');
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      print(
        'Item ${i + 1}: selectedItem=${item['selectedItem']}, qty=${item['qtyController'].text}, uom=${item['selectedUom']}, rate=${item['rateController'].text}, warehouse=${item['selectedWarehouse']}',
      );
    }

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstInvalidField();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields for all items'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Validate all items
    List<Map<String, dynamic>> items = [];
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final qtyText = item['qtyController'].text.trim();
      final rateText = item['rateController'].text.trim();
      final qty = double.tryParse(qtyText);
      final rate = double.tryParse(rateText);
      final itemCode = item['selectedItem'];
      final uom = item['selectedUom'];
      final warehouse = item['selectedWarehouse'];

      if (itemCode == null ||
          qty == null ||
          rate == null ||
          qty <= 0 ||
          rate <= 0 ||
          uom == null ||
          warehouse == null) {
        print(
          'Invalid item ${i + 1}: itemCode=$itemCode, qty=$qtyText, rate=$rateText, uom=$uom, warehouse=$warehouse',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please complete item ${i + 1} with valid values'),
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      items.add({
        'item_code': itemCode,
        'qty': qty,
        'uom': uom,
        'rate': rate,
        'warehouse': warehouse,
        'idx': i + 1,
      });
    }

    if (items.isEmpty) {
      print('No items added');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
      }
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final apiUrl = 'https://goshala.erpkey.in/api/resource/Delivery Note';
    final body = jsonEncode({
      'customer': _selectedCustomer,
      'docstatus': 0,
      'custom_mobile_entry' : 1,
      'posting_date':
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      'items': items,
    });
    print('Payload: $body');

    try {
      final token = await getToken();
      if (token == null) {
        print('Token is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication token not found')),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      print('Token: $token');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: body,
      );

      print('Submit Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery draft saved successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        String errorMsg = 'Failed to save delivery draft';
        try {
          final responseBody = jsonDecode(response.body);
          errorMsg =
              responseBody['exception']?.toString() ??
              responseBody['message']?.toString() ??
              errorMsg;
          print('Server error details: $responseBody');
        } catch (e) {
          print('Error parsing response: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } catch (e) {
      print('Submission exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error saving delivery draft: Check network or server',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _scrollToFirstInvalidField() {
    if (_selectedDate == null) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (_selectedCustomer == null) {
      _scrollController.animateTo(
        80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item['selectedItem'] == null) {
        final context = item['itemKey'].currentContext;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(Offset.zero).dy;
            _scrollController.animateTo(
              offset - 100,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
        return;
      }
      if (item['selectedUom'] == null) {
        final context = item['uomKey'].currentContext;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(Offset.zero).dy;
            _scrollController.animateTo(
              offset - 100,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
        return;
      }
      if (item['selectedWarehouse'] == null) {
        final context = item['warehouseKey'].currentContext;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.localToGlobal(Offset.zero).dy;
            _scrollController.animateTo(
              offset - 100,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
        return;
      }
      if (double.tryParse(item['qtyController'].text) == null ||
          double.tryParse(item['qtyController'].text)! <= 0) {
        _scrollController.animateTo(
          150 + i * 400,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
      if (double.tryParse(item['rateController'].text) == null ||
          double.tryParse(item['rateController'].text)! <= 0) {
        _scrollController.animateTo(
          150 + i * 400,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item['qtyController'].dispose();
      item['rateController'].dispose();
      item['amountController'].dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        _selectedDate != null
            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
            : '';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 4,
        automaticallyImplyLeading: true,
        title: const Center(
          child: Text(
            'Delivery Note',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  readOnly: true,
                                  onTap: _pickDate,
                                  decoration: InputDecoration(
                                    labelText: 'Select Date',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue[900],
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: formattedDate,
                                  ),
                                  validator: (value) {
                                    if (_selectedDate == null) {
                                      print('Validation failed: Date is null');
                                      return 'Please select a date';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: _selectedCustomer,
                                  hint: const Text('Select Customer'),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: Colors.blue[900],
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                  items:
                                      _customerList.isEmpty
                                          ? [
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text(
                                                'No customers available',
                                              ),
                                              enabled: false,
                                            ),
                                          ]
                                          : _customerList.map((
                                            String customer,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: customer,
                                              child: Text(customer),
                                            );
                                          }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCustomer = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      print(
                                        'Validation failed: Customer is null',
                                      );
                                      return 'Please select a customer';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Items',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) {
                                    final item = _items[index];
                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Item ${index + 1}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (_items.length > 1)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            _removeItem(index),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            DropdownButtonFormField<String>(
                                              key: item['itemKey'],
                                              value: item['selectedItem'],
                                              hint: const Text('Select Item'),
                                              decoration: InputDecoration(
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.inventory,
                                                  color: Colors.blue[900],
                                                ),
                                                errorStyle: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              items:
                                                  _itemList.isEmpty
                                                      ? [
                                                        const DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: null,
                                                          child: Text(
                                                            'No items available',
                                                          ),
                                                          enabled: false,
                                                        ),
                                                      ]
                                                      : _itemList.map((
                                                        String itemName,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: itemName,
                                                          child: Text(itemName),
                                                        );
                                                      }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  item['selectedItem'] =
                                                      newValue;
                                                  item['selectedUom'] = null;
                                                  item['selectedWarehouse'] =
                                                      'Finished Goods - SSS - G';
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} selectedItem is null',
                                                  );
                                                  return 'Please select item ${index + 1}';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            TextFormField(
                                              controller: item['qtyController'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Enter Quantity (Item ${index + 1})',
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.scale,
                                                  color: Colors.blue[900],
                                                ),
                                                errorStyle: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} qty is empty',
                                                  );
                                                  return 'Please enter quantity for item ${index + 1}';
                                                }
                                                final qty = double.tryParse(
                                                  value,
                                                );
                                                if (qty == null || qty <= 0) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} qty invalid',
                                                  );
                                                  return 'Please enter a valid positive number for item ${index + 1}';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            DropdownButtonFormField<String>(
                                              key: item['uomKey'],
                                              value: item['selectedUom'],
                                              hint: const Text('Select UOM'),
                                              decoration: InputDecoration(
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.category,
                                                  color: Colors.blue[900],
                                                ),
                                                errorStyle: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              items:
                                                  _uomList.isEmpty
                                                      ? [
                                                        const DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: null,
                                                          child: Text(
                                                            'No UOMs available',
                                                          ),
                                                          enabled: false,
                                                        ),
                                                      ]
                                                      : _uomList.map((
                                                        String uom,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: uom,
                                                          child: Text(uom),
                                                        );
                                                      }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  item['selectedUom'] =
                                                      newValue;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} selectedUom is null',
                                                  );
                                                  return 'Please select UOM for item ${index + 1}';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            DropdownButtonFormField<String>(
                                              key: item['warehouseKey'],
                                              value: item['selectedWarehouse'],
                                              hint: const Text(
                                                'Select Warehouse',
                                              ),
                                              decoration: InputDecoration(
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.store,
                                                  color: Colors.blue[900],
                                                ),
                                                errorStyle: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              items:
                                                  _warehouseList.isEmpty
                                                      ? [
                                                        const DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: null,
                                                          child: Text(
                                                            'No warehouses available',
                                                          ),
                                                          enabled: false,
                                                        ),
                                                      ]
                                                      : _warehouseList.map((
                                                        String warehouse,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: warehouse,
                                                          child: Text(
                                                            warehouse,
                                                          ),
                                                        );
                                                      }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  item['selectedWarehouse'] =
                                                      newValue;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} selectedWarehouse is null',
                                                  );
                                                  return 'Please select warehouse for item ${index + 1}';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  item['rateController'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Enter Rate (Item ${index + 1})',
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.currency_rupee,
                                                  color: Colors.blue[900],
                                                ),
                                                errorStyle: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} rate is empty',
                                                  );
                                                  return 'Please enter rate for item ${index + 1}';
                                                }
                                                final rate = double.tryParse(
                                                  value,
                                                );
                                                if (rate == null || rate <= 0) {
                                                  print(
                                                    'Validation failed: Item ${index + 1} rate invalid',
                                                  );
                                                  return 'Please enter a valid positive number for item ${index + 1}';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  item['amountController'],
                                              readOnly: true,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Amount (Item ${index + 1})',
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.calculate,
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Total Amount: ₹${_items.fold<double>(0, (sum, item) => sum + (double.tryParse(item['amountController'].text) ?? 0)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Another Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _submitDelivery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child:
                                      _isSubmitting
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Save Delivery Draft',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ),
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
