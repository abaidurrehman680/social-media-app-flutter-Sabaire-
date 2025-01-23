import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoryWidget extends StatelessWidget {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchSupabaseStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Map<String, dynamic>> statuses = snapshot.data ?? [];
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              var status = statuses[index];
              return buildStatusItem(context, status);
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchSupabaseStatuses() async {
    try {
      final response = await supabaseClient
          .from('status_media')
          .select()
          .then((data) => data as List<dynamic>);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch statuses from Supabase: $e');
    }
  }

  Widget buildStatusItem(BuildContext context, Map<String, dynamic> status) {
    final String imageUrl = status['url'] ?? '';
    final String username = status['username'] ?? 'Unknown User';
    final DateTime createdAt = DateTime.parse(status['createdAt'] ?? DateTime.now().toIso8601String());

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ViewStatusScreen(status: status),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 35.0,
            backgroundImage: CachedNetworkImageProvider(imageUrl),
          ),
          SizedBox(height: 5.0),
          Text(
            username,
            style: TextStyle(fontSize: 12.0),
          ),
          Text(
            timeago.format(createdAt),
            style: TextStyle(fontSize: 10.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ViewStatusScreen extends StatelessWidget {
  final Map<String, dynamic> status;

  ViewStatusScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = status['url'] ?? '';
    final String caption = status['caption'] ?? '';
    final List<dynamic> viewers = status['viewers'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Status'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                Text('Viewed by ${viewers.length} people'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
