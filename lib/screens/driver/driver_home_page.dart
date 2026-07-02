import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intelli_farm/screens/farmer/chatbot.dart';
import 'package:intelli_farm/screens/marketplace/order_detail_page.dart';

class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isOnline = false;
  String name = '';
  String profileImageUrl = '';
  bool isLoading = true;
  String currentLocation = "Fetching...";
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    fetchDriverInfo();
    _getLocationName();
  }

  Future<void> fetchDriverInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();

    setState(() {
      name = doc['name'] ?? 'No Name';
      profileImageUrl = doc.data()?['profileImageUrl'] ?? '';
      isOnline = doc.data()?['isOnline'] ?? false;
      isLoading = false;
    });
  }

  Future<void> _getLocationName() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          currentLocation = "Location Services Disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          currentLocation = "Permission Denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          currentLocation = "${place.locality ?? 'Unknown'}, ${place.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      setState(() => currentLocation = "Error fetching location");
    }
  }

  Future<void> toggleOnlineStatus(bool value) async {
    setState(() => isOnline = value);
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'isOnline': isOnline,
    });
  }

  Future<void> acceptRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('driver_requests').doc(requestId).update({
      'status': 'accepted',
      'assignedTo': currentUser!.uid,
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('driver_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Widget buildRequestCard(Map<String, dynamic> data, String id, {bool showActions = true}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text("📦 ${data['pickup']} → ${data['drop']}"),
        subtitle: Text("📅 ${data['date']} at ${data['time']}\n🚚 Load: ${data['load']}"),
        trailing: showActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    tooltip: "Accept",
                    onPressed: () => acceptRequest(id),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    tooltip: "Reject",
                    onPressed: () => rejectRequest(id),
                  ),
                ],
              )
            : Icon(Icons.check_circle, color: Colors.green),
        onTap: () {
          if (!showActions) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailPage(orderData: data),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatbotScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.smart_toy),
        tooltip: 'Chatbot',
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDriverInfo,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _driverInfoCard(),
                    SizedBox(height: 20),
                    _locationCard(),
                    SizedBox(height: 30),
                    Text("🕒 Pending Requests", style: Theme.of(context).textTheme.titleLarge),
                    _requestList(status: 'pending', isAccepted: false),
                    SizedBox(height: 30),
                    Text("✅ Accepted Requests", style: Theme.of(context).textTheme.titleLarge),
                    _requestList(status: 'accepted', isAccepted: true),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _driverInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade100,
              backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
              child: profileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 50, color: Colors.green.shade800)
                  : null,
            ),
            SizedBox(height: 16),
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: Text("Online Status"),
              value: isOnline,
              onChanged: toggleOnlineStatus,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    return GestureDetector(
      onTap: () async {
        if (currentPosition == null) await _getLocationName();
        if (currentPosition != null) {
          Navigator.pushNamed(
            context,
            '/weather',
            arguments: {
              'lat': currentPosition!.latitude,
              'lon': currentPosition!.longitude,
              'location': currentLocation,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to fetch location")),
          );
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blueGrey, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Location: $currentLocation",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestList({required String status, required bool isAccepted}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('driver_requests')
          .where(isAccepted ? 'assignedTo' : 'to', isEqualTo: currentUser!.uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Text("No $status requests.");
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return buildRequestCard(data, doc.id, showActions: !isAccepted);
          }).toList(),
        );
      },
    );
  }
}
