import 'package:flutter/material.dart';
import 'package:social/models/status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatusScreen extends StatelessWidget {
  final dynamic status;
  final bool isFirebase;

  const StatusScreen({Key? key, required this.status, required this.isFirebase}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String imageUrl = isFirebase ? status['mediaUrl'] : status['url'];
    final String caption = isFirebase ? status['caption'] : 'No caption available';
    final int views = isFirebase ? (status['viewers'] as List).length : 0;

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(caption),
          ),
          Text('Views: $views'),
        ],
      ),
    );
  }
}
