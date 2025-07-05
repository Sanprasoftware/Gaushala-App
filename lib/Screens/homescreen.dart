import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  double _totalInQty = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTotalInQty();
  }

  Future<void> _fetchTotalInQty() async {
    final String apiUrl = 'https://goshala.erpkey.in/api/method/frappe.desk.query_report.run';
    final uri = Uri.parse(apiUrl).replace(
      queryParameters: {
        'report_name': 'Stock Balance',
        'filters': jsonEncode({
          'company': 'Goshala',
          'from_date': '2025-06-05',
          'to_date': '2025-07-05',
          'warehouse': 'Finished Goods - SSS - G',
          'valuation_field_type': 'Currency',
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
          'Referer': 'https://goshala.erpkey.in/app/query-report/Stock Balance',
        },
      );

      print('Total In Qty Response Status: ${response.statusCode}');
      print('Total In Qty Response Headers: ${response.headers}');
      print('Total In Qty Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data'); // Debug parsed JSON
        final List<dynamic> results = data['message']['result'] ?? [];
        print('Results Array: $results'); // Debug results array
        double total = 0.0;
        for (var item in results) {
          print('Processing item: $item'); // Debug each item
          if (item is Map && item['in_qty'] != null) {
            total += (item['in_qty'] as num).toDouble();
            print('Added in_qty: ${item['in_qty']} to total: $total');
          } else if (item is List && item[0] == 'Total' && item.length > 5) {
            total = (item[5] as num).toDouble(); // Use bal_qty from total row
            print('Used total row bal_qty: ${item[5]} to set total: $total');
            break;
          }
        }
        if (mounted) {
          setState(() {
            _totalInQty = total > 0 ? total : 0.0; // Ensure non-negative
          });
        }
      } else {
        print('API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch total in qty: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Detailed Total In Qty Fetch Exception: $e');
      if (mounted) {
        setState(() {
          _totalInQty = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching total in qty: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await _storage.delete(key: 'api_key');
              await _storage.delete(key: 'api_secret');
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); // Navigate to login and clear stack
            },
            child: const Text('Yes'),
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
        automaticallyImplyLeading: false, // Removes the back arrow
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Curved bottom corners
          ),
        ),
        title: Center(
          child: Image.asset(
            'assets/logo.png', // Logo centered in app bar
            height: 100, // Reduced for better fit
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red, size: 30);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue[900], size: 30),
            onPressed: _logout,
          ),
        ], // Logout button in top right
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFFF99)], // Gold to light yellow gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Animated Greeting and Welcome Text on left
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to left
                  children: [
                    Text(
                      'Hello, Pranav Wani', // Greeting on left
                      style: const TextStyle(
                        fontSize: 20, // Reduced size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Welcome to Gaushala App', // Smaller welcome text
                      style: const TextStyle(
                        fontSize: 14, // Smaller size
                        color: Colors.blueGrey, // Different color
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Static Image Placeholder with Decorative Border
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[900]!, width: 2),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  'assets/slider1.jpg', // Static image placeholder
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Image not found', style: TextStyle(color: Colors.red)));
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Enhanced Total Collection Row with Card and Total In Qty
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 6,
                color: Colors.white.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.blue[900]!.withOpacity(0.3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/cow.png', // Cow logo on left
                        height: 50,
                        width: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.agriculture, color: Colors.green, size: 50);
                        },
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Total Collection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Total In Qty (Litres)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE4B5), // Light golden background
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Text(
                          '$_totalInQty L',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Three Round Icons with Connectivity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/supplier');
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[900]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.transparent,
                          child: const Icon(Icons.store, color: Colors.white, size: 35),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Supplier',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/collection');
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[900]!, Colors.green[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.transparent,
                          child: const Icon(Icons.money, color: Colors.white, size: 35),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Collection',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/report');
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[900]!, Colors.red[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.transparent,
                          child: const Icon(Icons.description, color: Colors.white, size: 35),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(), // Pushes footer to the bottom
            // Footer with curved corners
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20), // Curved top corners
                ),
              ),
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
          ],
        ),
      ),
    );
  }
}