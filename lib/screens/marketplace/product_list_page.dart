import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Listings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) return Center(child: Text("No products available."));

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final farmerId = data['farmerId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc('uid').get(),
                builder: (context, farmerSnapshot) {
                  if (farmerSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final farmerData = farmerSnapshot.data?.data() as Map<String, dynamic>?;

                  return Card(
                    margin: EdgeInsets.all(10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['imageUrl'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              data['imageUrl'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? 'No Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("Price: ₹${data['price']}", style: TextStyle(fontSize: 16)),
                              Text("Category: ${data['category']}", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              SizedBox(height: 10),
                              if (farmerData != null) ...[
                                Text("Farmer Name: ${farmerData['name'] ?? 'N/A'}"),
                                Text("Phone: ${farmerData['phone'] ?? 'N/A'}"),
                              ],
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final currentUser = FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('You must be logged in to send a request.')),
                                      );
                                      return;
                                    }

                                    final productId = products[index].id;

                                    await FirebaseFirestore.instance.collection('dealer_requests').add({
                                      'productId': productId,
                                      'productName': data['name'] ?? '',
                                      'productPrice': data['price'] ?? '',
                                      'category': data['category'] ?? '',
                                      'imageUrl': data['imageUrl'] ?? '',
                                      'farmerId': farmerId,
                                      'dealerId': currentUser.uid,
                                      'status': 'pending',
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order request sent to the farmer.')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to send request: $e')),
                                    );
                                  }
                                },
                                child: Text('Request Order'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
