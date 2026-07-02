import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DealerFarmerChat extends StatefulWidget {
  final String dealerId; // pass dealer ID from previous screen

  const DealerFarmerChat({super.key, required this.dealerId});

  @override
  State<DealerFarmerChat> createState() => _DealerFarmerChatState();
}

class _DealerFarmerChatState extends State<DealerFarmerChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      FirebaseFirestore.instance.collection('chats').add({
        'sender': 'dealer_${widget.dealerId}',
        'receiver': 'farmer',
        'message': message,
        'timestamp': Timestamp.now(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Farmers')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs.where((doc) {
                  return (doc['sender'].toString().startsWith('dealer_') &&
                          doc['receiver'] == 'farmer') ||
                      (doc['sender'] == 'farmer' &&
                          doc['receiver'] == 'dealer_${widget.dealerId}');
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isDealer = msg['sender'] == 'dealer_${widget.dealerId}';
                    return Align(
                      alignment:
                          isDealer ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDealer ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg['message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
