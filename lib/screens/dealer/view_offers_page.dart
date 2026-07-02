import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewOffersPage extends StatefulWidget {
  final String productId;
  const ViewOffersPage({super.key, required this.productId});

  @override
  State<ViewOffersPage> createState() => _ViewOffersPageState();
}

class _ViewOffersPageState extends State<ViewOffersPage> {
  Map<String, dynamic>? productData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _fetchProduct() async {
    final doc = await _firestore.collection('products').doc(widget.productId).get();
    setState(() {
      productData = doc.data();
    });
  }

  Future<void> _acceptOffer(String offerId, Map<String, dynamic> offerData) async {
    try {
      await _firestore.collection('products').doc(widget.productId).update({
        'acceptedOffer': offerData,
        'status': 'Accepted',
        'acceptedOfferId': offerId,
      });
      await _fetchProduct();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Offer accepted.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _cancelAcceptedOffer() async {
    try {
      await _firestore.collection('products').doc(widget.productId).update({
        'acceptedOffer': FieldValue.delete(),
        'status': 'Pending',
        'acceptedOfferId': FieldValue.delete(),
      });
      await _fetchProduct();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Acceptance cancelled.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _startChat(String dealerId, String dealerName) {
    Navigator.pushNamed(context, '/chat', arguments: {
      'receiverId': dealerId,
      'receiverName': dealerName,
    });
  }

  void _callDealer(String phoneNumber) async {
    final uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot launch dialer.")),
      );
    }
  }

  Future<String?> _getDealerPhone(String dealerId) async {
    try {
      final doc = await _firestore.collection('users').doc(dealerId).get();
      return doc.data()?['mobile']?.toString();
    } catch (e) {
      print("Error fetching dealer phone: $e");
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  @override
  Widget build(BuildContext context) {
    final productRef = _firestore.collection('products').doc(widget.productId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Offers for Product"),
        backgroundColor: Colors.green[700],
      ),
      body: productData == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: productRef.collection('offers').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No offers placed yet."));
                }

                final acceptedOffer = productData?['acceptedOffer'];
                final offers = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offerDoc = offers[index];
                    final offer = offerDoc.data() as Map<String, dynamic>;
                    final offerId = offerDoc.id;

                    final dealerId = offer['dealerId'] ?? '';
                    final dealerName = offer['dealerName'] ?? 'Unknown';
                    final offerPrice = offer['offerPrice'] ?? 'N/A';

                    final isAccepted = acceptedOffer != null &&
                        acceptedOffer['dealerId'] == dealerId &&
                        acceptedOffer['offerPrice'].toString() == offerPrice.toString();

                    return FutureBuilder<String?>(
                      future: _getDealerPhone(dealerId),
                      builder: (context, phoneSnapshot) {
                        final phone = phoneSnapshot.data ?? '';

                        return Card(
                          color: isAccepted ? Colors.green[50] : null,
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isAccepted ? BorderSide(color: Colors.green, width: 2) : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Dealer: $dealerName",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green[900],
                                      ),
                                    ),
                                    if (isAccepted)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Chip(
                                          label: Text("ACCEPTED", style: TextStyle(color: Colors.white)),
                                          backgroundColor: Colors.green[700],
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text("Offered Price: ₹$offerPrice"),
                                if (offer['message'] != null && offer['message'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text("Message: ${offer['message']}", style: TextStyle(color: Colors.grey[700])),
                                  ),
                                SizedBox(height: 10),

                                if (!isAccepted)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _acceptOffer(offerId, offer),
                                      icon: Icon(Icons.check_circle_outline),
                                      label: Text(acceptedOffer == null ? "Accept Offer" : "Change Acceptance"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: acceptedOffer == null ? Colors.green[700] : Colors.orange[700],
                                      ),
                                    ),
                                  ),

                                if (isAccepted) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: phone.isNotEmpty ? () => _callDealer(phone) : null,
                                        icon: Icon(Icons.call),
                                        label: Text("Call Dealer"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _startChat(dealerId, dealerName),
                                        icon: Icon(Icons.chat),
                                        label: Text("Chat"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _cancelAcceptedOffer,
                                    icon: Icon(Icons.cancel),
                                    label: Text("Cancel Acceptance"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                                  ),
                                ]
                              ],
                            ),
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