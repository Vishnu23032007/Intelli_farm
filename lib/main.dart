import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intelli_farm/screens/auth/login_page.dart';
import 'package:intelli_farm/screens/auth/register_page.dart';
import 'package:intelli_farm/screens/dealer/dealer_home.dart';
import 'package:intelli_farm/screens/marketplace/browse_product_page.dart';
import 'package:intelli_farm/screens/farmer/farmer_home.dart';
import 'package:intelli_farm/screens/marketplace/product_list_page.dart';
import 'package:intelli_farm/screens/marketplace/product_upload_page.dart';
import 'package:intelli_farm/screens/farmer/farmer_profile_page.dart';
import 'package:intelli_farm/screens/farmer/crop_advisory_page.dart';
import 'package:intelli_farm/screens/marketplace/marketplace_page.dart';
import 'package:intelli_farm/screens/dealer/dealer_profile_page.dart';
import 'package:intelli_farm/screens/farmer/chatbot.dart';
import 'package:intelli_farm/screens/farmer/rain_prediction.dart';
import 'package:intelli_farm/screens/common/employee_page.dart';
import 'package:intelli_farm/screens/farmer/customer_care_page.dart';
import 'package:intelli_farm/screens/marketplace/my_products_page.dart';
import 'package:intelli_farm/screens/driver/driver_home_page.dart';
import 'package:intelli_farm/screens/driver/driver_list_page.dart';
import 'package:intelli_farm/screens/marketplace/request_order_page.dart';
import 'package:intelli_farm/screens/marketplace/my_order_page.dart';
import 'package:intelli_farm/screens/marketplace/my_order_requests_page.dart';
import 'package:intelli_farm/screens/marketplace/accepted_orders_page.dart';
import 'package:intelli_farm/screens/farmer/weather_page.dart';
import 'package:intelli_farm/screens/common/dealer_farmer_chat.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(IntelliFarmApp());
}

class IntelliFarmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelliFarm',
      theme: ThemeData(
        primaryColor: Color(0xFF4CAF50),
        scaffoldBackgroundColor: Color(0xFFF1F8E9),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF388E3C),
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4CAF50),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/farmerHome': (context) => FarmerHome(),
        '/dealerHome': (context) => DealerHome(),
        '/upload': (context) => ProductUploadPage(),
        '/list': (context) => ProductListPage(),
        '/chatbot': (context) => ChatbotScreen(),
        '/farmer_profile': (context) => FarmerProfilePage(),
        '/dealerProfile': (context) => DealerProfilePage(),
        '/rainPrediction': (context) => RainPredictionScreen(),
        '/employeePage': (context) => EmployeePage(),
        '/customerCare': (context) => const CustomerCarePage(),
        '/myProducts': (context) => const MyProductsPage(),
        '/driverHome': (context) =>  DriverHomePage(),
        '/drivers': (context) => DriverListPage(),
        '/requestOrder': (context) => RequestOrderPage(),
        '/myOrderRequests' : (context) => MyOrderRequestsPage(),
        '/acceptedOrders': (context) => const AcceptedOrdersPage(),
        '/marketplace' : (context) => MarketplacePage(),
        '/browseProducts' : (context) => BrowseProductsPage(),
        '/cropAdvisory' : (context) => CropAdvisoryPage(),
        '/dealerFarmerChat': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return DealerFarmerChat(dealerId: args['dealerId']);
},

        '/myOrders': (context) => MyOrdersPage(),
        '/weather': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return WeatherForecastPage(
    lat: args['lat'],
    lon: args['lon'],
    locationName: args['location'],
  );
},



      },
    );
  }
}