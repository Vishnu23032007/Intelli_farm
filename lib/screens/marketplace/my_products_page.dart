import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intelli_farm/screens/marketplace/edit_product_page.dart';
import 'package:intelli_farm/screens/dealer/view_offers_page.dart';

class MyProductsPage extends StatelessWidget {
  const MyProductsPage({super.key});

  void _deleteProduct(String productId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editProduct(
    BuildContext context,
    Map<String, dynamic> productData,
    String productId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductPage(productData: productData, productId: productId),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> product,
    String productId,
    bool isNegotiable,
    dynamic price,
    String priceLabel,
    String typeLabel,
    int offerCount,
  ) {
    final isSold = product['status'] == 'Sold';
    final buyerName = product['buyerName'];

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product['name'] ?? 'Unnamed Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isNegotiable ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNegotiable ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text("$priceLabel: ₹${price ?? 'N/A'}"),
            Text("Quantity: ${product['quantity'] ?? 'N/A'}"),
            Text("Category: ${product['category'] ?? 'N/A'}"),

            if (!isNegotiable && isSold) ...[
              SizedBox(height: 10),
              Text(
                buyerName != null
                    ? "Ordered by Dealer: $buyerName"
                    : "Ordered by a dealer",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            if (isNegotiable && offerCount > 0) ...[
              SizedBox(height: 10),
              Text(
                "$offerCount offer(s) received",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewOffersPage(productId: productId),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility),
                  label: Text("View Offers"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                  ),
                ),
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editProduct(context, product, productId),
                  icon: Icon(Icons.edit, color: Colors.blue),
                  label: Text("Edit", style: TextStyle(color: Colors.blue)),
                ),
                TextButton.icon(
                  onPressed: () => _deleteProduct(productId, context),
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Products")),
        body: Center(child: Text("User not logged in")),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("My Products"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('farmerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No products uploaded yet."));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final product = productDoc.data() as Map<String, dynamic>;
              final productId = productDoc.id;

              final isNegotiable = product.containsKey('startingPrice');
              final price = isNegotiable ? product['startingPrice'] : product['price'];
              final priceLabel = isNegotiable ? "Starting Price" : "Fixed Price";
              final typeLabel = isNegotiable ? "Negotiable" : "Fixed";

              if (isNegotiable) {
                return FutureBuilder<QuerySnapshot>(
                  future: productDoc.reference.collection('offers').get(),
                  builder: (context, offerSnapshot) {
                    int offerCount = offerSnapshot.data?.docs.length ?? 0;

                    return _buildProductCard(
                      context,
                      product,
                      productId,
                      isNegotiable,
                      price,
                      priceLabel,
                      typeLabel,
                      offerCount,
                    );
                  },
                );
              } else {
                return _buildProductCard(
                  context,
                  product,
                  productId,
                  isNegotiable,
                  price,
                  priceLabel,
                  typeLabel,
                  0,
                );
              }
            },
          );
        },
      ),
    );
  }
}