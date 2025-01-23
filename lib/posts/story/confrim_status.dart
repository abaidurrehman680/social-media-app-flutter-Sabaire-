import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social/models/status.dart';
import 'package:social/view_models/status/status_view_model.dart';
import 'package:social/widgets/indicators.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/enum/message_type.dart';

class ConfirmStatus extends StatefulWidget {
  @override
  _ConfirmStatusState createState() => _ConfirmStatusState();
}

class _ConfirmStatusState extends State<ConfirmStatus> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    StatusViewModel viewModel = Provider.of<StatusViewModel>(context);
    return Scaffold(
      body: LoadingOverlay(
        isLoading: loading,
        progressIndicator: circularProgress(context),
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Image.file(viewModel.mediaUrl!),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 10.0,
        child: Container(
          constraints: BoxConstraints(maxHeight: 100.0),
          child: TextFormField(
            style: TextStyle(fontSize: 15.0, color: Theme.of(context).textTheme.titleLarge?.color),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(10.0),
              enabledBorder: InputBorder.none,
              border: InputBorder.none,
              hintText: "Type your caption",
              hintStyle: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
            ),
            onSaved: (val) {
              viewModel.setDescription(val!);
            },
            onChanged: (val) {
              viewModel.setDescription(val);
            },
            maxLines: null,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.done, color: Colors.white),
        onPressed: () async {
          setState(() {
            loading = true;
          });

          try {
            // Upload media to Supabase and get URL
            String url = await uploadMediaToSupabase(viewModel.mediaUrl!);

            // Create status model
            StatusModel status = StatusModel(
              url: url,
              caption: viewModel.description,
              type: MessageType.IMAGE,
              time: Timestamp.now(),
              statusId: Uuid().v1(), // Unique status ID
              viewers: [],
            );

            // Save the status in Firebase
            await FirebaseFirestore.instance.collection('statuses').add({
              'userId': FirebaseAuth.instance.currentUser!.uid,
              'username': FirebaseAuth.instance.currentUser!.displayName ?? 'User',
              'caption': viewModel.description,
              'mediaUrl': url, // Store the media URL
              'time': Timestamp.now(),
              'statusId': status.statusId,
              'viewers': status.viewers,
            });

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status uploaded successfully')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload status: ${e.toString()}')));
          } finally {
            setState(() {
              loading = false;
            });

            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Future<String> uploadMediaToSupabase(File image) async {
    final supabase.SupabaseClient client = supabase.Supabase.instance.client;
    final String fileName = 'status_media/${DateTime.now().millisecondsSinceEpoch}.png'; // Ensure unique filename

    final storage = client.storage.from('status_media'); // Bucket name: "status_media"

    try {
      // Upload the file to Supabase
      await storage.upload(fileName, image);

      // Retrieve and return the public URL of the uploaded file
      final fileUrl = storage.getPublicUrl(fileName);
      return fileUrl;
    } catch (e) {
      throw Exception('Failed to upload media to Supabase: $e');
    }
  }
}
