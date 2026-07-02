import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final driversRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Driver')
        .where('driverStatus', isEqualTo: 'approved');

    return Scaffold(
      appBar: AppBar(title: const Text("Available Drivers")),
      body: StreamBuilder<QuerySnapshot>(
        stream: driversRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error loading drivers'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final drivers = snapshot.data!.docs;

          if (drivers.isEmpty) return Center(child: Text("No drivers online."));

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(driver['profileImageUrl'] ?? ''),
                    backgroundColor: Colors.green[100],
                  ),
                  title: Text(driver['name'] ?? ''),
                  subtitle: Text(driver['email'] ?? ''),
                  trailing: ElevatedButton(
                    child: Text("Request"),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/requestOrder',
                        arguments: driver,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
