import 'package:flutter/material.dart';
import 'package:gaushala/Screens/add_collection_screen.dart';
import 'package:gaushala/Screens/add_supplier_screen.dart';
import 'package:gaushala/Screens/collection_screen.dart';
import 'package:gaushala/Screens/homescreen.dart';
import 'package:gaushala/Screens/loginpage.dart';
import 'package:gaushala/Screens/report_screen.dart';
import 'package:gaushala/Screens/supplier_screen.dart';

void main() {
  runApp(const GaushalaApp());
}

class GaushalaApp extends StatelessWidget {
  const GaushalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gaushala',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        useMaterial3: true,
      ),
      initialRoute: '/login', // Start with login page
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/supplier': (context) => const SupplierScreen(),
        '/collection': (context) => const CollectionScreen(),
        '/add_collection': (context) => const AddCollectionScreen(),
        '/report': (context) => const ReportScreen(),
        '/about': (context) => const PlaceholderScreen(title: 'About Page'),
        '/dashboard': (context) => const PlaceholderScreen(title: 'Dashboard Page'),
        '/add_supplier': (context) => AddSupplierScreen(refreshSupplierList: () {}), // Default empty function
      },
    );
  }
}

// Placeholder widget for new pages
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Text(
          '$title Content Coming Soon!',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}