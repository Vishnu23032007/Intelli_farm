import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> _fetchDealerOffers() async {
    final List<Map<String, dynamic>> myOffers = [];

    final productsSnapshot = await _firestore.collection('products').get();

    for (var productDoc in productsSnapshot.docs) {
      final productData = productDoc.data();
      final productId = productDoc.id;

      final offerSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('offers')
          .where('dealerId', isEqualTo: currentUserId)
          .get();

      if (offerSnapshot.docs.isNotEmpty) {
        final myOffer = offerSnapshot.docs.first.data();
        final farmerId = productData['farmerId'];

        final accepted = productData['acceptedOffer'] != null &&
            productData['acceptedOffer']['dealerId'] == currentUserId;

        myOffers.add({
          'productId': productId,
          'productName': productData['name'],
          'offerPrice': myOffer['offerPrice'],
          'status': accepted ? 'Accepted' : 'Pending',
          'farmerId': farmerId,
        });
      }
    }

    return myOffers;
  }

  Future<Map<String, dynamic>?> _getFarmerDetails(String farmerId) async {
    try {
      final doc = await _firestore.collection('users').doc(farmerId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching farmer details: $e");
      return null;
    }
  }

  void _showFarmerDetails(BuildContext context, String farmerId) async {
    final farmer = await _getFarmerDetails(farmerId);

    if (farmer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Farmer details not found.")),
      );
      return;
    }

    final name = farmer['name'] ?? 'Unknown';
    final phone = farmer['mobile']?.toString() ?? 'Not Available';
    final email = farmer['email'] ?? 'Not Available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Farmer Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: $name"),
            SizedBox(height: 4),
            Text("Phone: $phone"),
            SizedBox(height: 4),
            Text("Email: $email"),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: phone != 'Not Available' ? () => _callFarmer(phone) : null,
                  icon: Icon(Icons.call),
                  label: Text("Call"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _startChat(context, farmerId, name),
                  icon: Icon(Icons.chat),
                  label: Text("Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _callFarmer(String phoneNumber) async {
    final uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch dialer.")),
      );
    }
  }

  void _startChat(BuildContext context, String farmerId, String farmerName) {
    Navigator.pushNamed(context, '/chat', arguments: {
      'receiverId': farmerId,
      'receiverName': farmerName,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blue[800],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDealerOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final offers = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isAccepted = offer['status'] == 'Accepted';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isAccepted ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  title: Text(offer['productName'] ?? 'Product'),
                  subtitle: Text("Your Offer: ₹${offer['offerPrice']}"),
                  trailing: Chip(
                    label: Text(
                      offer['status'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        isAccepted ? Colors.green[700] : Colors.orange[700],
                  ),
                  onTap: () {
                    _showFarmerDetails(context, offer['farmerId']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}