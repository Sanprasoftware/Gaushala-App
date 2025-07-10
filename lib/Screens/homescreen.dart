import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  double _totalInQty = 0.0;
  String _userFullName = '';
  int _maleCount = 0;
  int _femaleCount = 0;
  Map<String, int> _speciesCounts = {};

  final List<String> _sliderImages = [
    'assets/slider1.jpg',
    'assets/slider2.jpg',
    'assets/slider3.jpg',
  ];

  int _currentImageIndex = 0;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _fetchTotalInQty();
    _startImageRotation();
    _loadUserFullName();
    _fetchSupplierSummary();
  }

  Future<void> _loadUserFullName() async {
    final name = await _storage.read(key: 'full_name');
    if (mounted) {
      setState(() {
        _userFullName = name ?? 'User'; // fallback if null
      });
    }
  }

  void _startImageRotation() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _sliderImages.length;
      });
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSupplierSummary() async {
    final uri = Uri.parse(
      'https://goshala.erpkey.in/api/resource/Supplier?fields=["custom_gender","custom_animal_type"]&limit_page_length=1000',
    );

    try {
      final apiKey = await _storage.read(key: "api_key") ?? "";
      final apiSecret = await _storage.read(key: "api_secret") ?? "";

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'token $apiKey:$apiSecret',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> suppliers = data['data'] ?? [];

        int male = 0;
        int female = 0;
        Map<String, int> speciesMap = {};

        for (var s in suppliers) {
          final gender =
              (s['custom_gender'] ?? '').toString().trim().toLowerCase();
          final species = (s['custom_animal_type'] ?? '').toString().trim();

          if (gender == 'male') male++;
          if (gender == 'female') female++;

          if (species.isNotEmpty) {
            speciesMap[species] = (speciesMap[species] ?? 0) + 1;
          }
        }

        if (mounted) {
          setState(() {
            _maleCount = male;
            _femaleCount = female;
            _speciesCounts = speciesMap;
          });
        }
      }
    } catch (e) {
      print('Error fetching supplier summary: $e');
    }
  }

  Future<void> _fetchTotalInQty() async {
    final String apiUrl =
        'https://goshala.erpkey.in/api/method/goshala_sanpra.custom_pyfile.login_master.get_total_stock_qty?item_code=Cow&warehouse=Finished%20Goods%20-%20SSS%20-%20G';

    try {
      final String apiSecret = await _storage.read(key: "api_secret") ?? "";
      final String apiKey = await _storage.read(key: "api_key") ?? "";

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'token $apiKey:$apiSecret',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double qty = (data['message']['total_qty'] ?? 0.0).toDouble();
        if (mounted) {
          setState(() {
            _totalInQty = qty;
          });
        }
      } else {
        throw Exception('Failed to fetch total stock qty');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalInQty = 0.0;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching stock qty: $e')));
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await _storage.delete(key: 'api_key');
                  await _storage.delete(key: 'api_secret');
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
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
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 100,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red, size: 30),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue[900], size: 30),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFFF99)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Your existing widgets inside Column (from Padding -> Row -> Cards etc.)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $_userFullName',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.blueGrey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Welcome To संवेदना गौशाळा',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Animated Image Slider
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[900]!, width: 2),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
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
                        child: AnimatedSwitcher(
                          duration: const Duration(seconds: 1),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(1.0, 0.0), // Slide from right
                              end: Offset.zero,
                            ).animate(animation);

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            _sliderImages[_currentImageIndex],
                            key: ValueKey<String>(
                              _sliderImages[_currentImageIndex],
                            ),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  'Image not found',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total Collection Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 6,
                        color: Colors.white.withOpacity(0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Colors.blue[900]!.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/cow-logo.png',
                                    height: 50,
                                    width: 50,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.agriculture,
                                              color: Colors.green,
                                              size: 50,
                                            ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'Total Qty (Litres): ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '$_totalInQty L',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Text(
                                              'Male: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '$_maleCount',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Text(
                                              'Total Animals: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${_maleCount + _femaleCount}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Text(
                                              'Female: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '$_femaleCount',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.pink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 1),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 4.5,
                                children:
                                    _speciesCounts.entries.map((entry) {
                                      return Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.yellow[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber,
                                          ),
                                        ),
                                        child: Text(
                                          '${entry.key} = ${entry.value}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Navigation Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: GridView.count(
                        crossAxisCount: 4, // 3 items per row
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 5, // ✅ reduce vertical spacing here
                        childAspectRatio: 0.85,
                        children: [
                          _buildIcon(
                            Icons.store,
                            'Supplier',
                            '/supplier',
                            Colors.blue[900]!,
                          ),
                          _buildIcon(
                            Icons.money,
                            'Collection',
                            '/collection',
                            Colors.blue[900]!,
                          ),
                          _buildIcon(
                            Icons.description,
                            'Report',
                            '/report',
                            Colors.blue[900]!,
                          ),
                          _buildIcon(
                            Icons.swap_horiz,
                            'Material',
                            '/material_transfer',
                            Colors.blue[900]!,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );

    // Fixed Footer
    // Positioned(
    //   left: 0,
    //   right: 0,
    //   bottom: 0,
    //   child: Container(
    //     decoration: BoxDecoration(
    //       color: Colors.blue[900],
    //       borderRadius: const BorderRadius.vertical(
    //         top: Radius.circular(20),
    //       ),
    //     ),
    //     padding: const EdgeInsets.all(12.0),
    //     child: Row(
    //       mainAxisAlignment: MainAxisAlignment.spaceAround,
    //       children: [
    //         IconButton(
    //           icon: const Icon(Icons.home, color: Colors.white, size: 30),
    //           onPressed: () => Navigator.pushNamed(context, '/home'),
    //         ),
    //         IconButton(
    //           icon: const Icon(Icons.info, color: Colors.white, size: 30),
    //           onPressed: () => Navigator.pushNamed(context, '/about'),
    //         ),
    //       ],
    //     ),
    //   ),
    // ),
  }

  Widget _buildIcon(IconData icon, String label, String route, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CircleAvatar(
              radius: 28, // smaller size
              backgroundColor: Colors.blue[900],
              child: Icon(icon, color: Colors.white, size: 30), // smaller icon
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/home'),
          ),
          IconButton(
            icon: const Icon(Icons.info, color: Colors.white, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
    );
  }
}
