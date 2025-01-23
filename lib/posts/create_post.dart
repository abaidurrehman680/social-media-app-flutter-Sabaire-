import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social/components/custom_image.dart';
import 'package:social/view_models/auth/posts_view_model.dart';
import 'package:social/widgets/indicators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class CreatePost extends StatefulWidget {
  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  @override
  Widget build(BuildContext context) {
    PostsViewModel viewModel = Provider.of<PostsViewModel>(context);
    currentUserId() {
      return FirebaseAuth.instance.currentUser!.uid;
    }

    return WillPopScope(
      onWillPop: () async {
        await viewModel.resetPost();
        return true;
      },
      child: LoadingOverlay(
        progressIndicator: circularProgress(context),
        isLoading: viewModel.loading,
        child: Scaffold(
          key: viewModel.scaffoldKey,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Ionicons.close_outline),
              onPressed: () {
                viewModel.resetPost();
                Navigator.pop(context);
              },
            ),
            title: Text('Create a Post'.toUpperCase()),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () async {
                  await uploadPost(context, viewModel);
                  Navigator.pop(context);
                  viewModel.resetPost();
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Post'.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              )
            ],
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            children: [
              SizedBox(height: 15.0),
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUserId()).snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    var user = snapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25.0,
                        backgroundImage: NetworkImage(user['profilePicture'] ?? ''),
                      ),
                      title: Text(
                        user['username'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email'] ?? ''),
                    );
                  }
                  return Container();
                },
              ),
              InkWell(
                onTap: () => showImageChoices(context, viewModel),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width - 30,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  child: viewModel.imgLink != null
                      ? CustomImage(
                    imageUrl: viewModel.imgLink,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width - 30,
                    fit: BoxFit.cover,
                  )
                      : viewModel.mediaUrl == null
                      ? Center(
                    child: Text(
                      'Upload a Photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  )
                      : Image.file(
                    viewModel.mediaUrl!,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width - 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'Post Caption'.toUpperCase(),
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextFormField(
                initialValue: viewModel.description,
                decoration: InputDecoration(
                  hintText: 'Eg. This is a very beautiful place!',
                  focusedBorder: UnderlineInputBorder(),
                ),
                maxLines: null,
                onChanged: (val) => viewModel.setDescription(val),
              ),
              SizedBox(height: 20.0),
              Text(
                'Location'.toUpperCase(),
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.all(0.0),
                title: Container(
                  width: 250.0,
                  child: TextFormField(
                    controller: viewModel.locationTEC,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(0.0),
                      hintText: 'Lahore, Pakistan!',
                      focusedBorder: UnderlineInputBorder(),
                    ),
                    maxLines: null,
                    onChanged: (val) => viewModel.setLocation(val),
                  ),
                ),
                trailing: IconButton(
                  tooltip: "Use your current location",
                  icon: Icon(
                    CupertinoIcons.map_pin_ellipse,
                    size: 25.0,
                  ),
                  iconSize: 30.0,
                  color: Theme.of(context).colorScheme.secondary,
                  onPressed: () => viewModel.getLocation(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  showImageChoices(BuildContext context, PostsViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: .6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Select Image',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Ionicons.camera_outline),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickImage(camera: true);
                },
              ),
              ListTile(
                leading: Icon(Ionicons.image),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Upload the post image and post details to Firestore and Supabase
  // Upload the post image and post details to Firestore and Supabase
  Future<void> uploadPost(BuildContext context, PostsViewModel viewModel) async {
    if (viewModel.mediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image first')));
      return;
    }

    setState(() {
      viewModel.loading = true;
    });

    try {
      final file = viewModel.mediaUrl!;
      final fileName = 'post_images/${DateTime.now().millisecondsSinceEpoch}.png';

      final storage = supabase.Supabase.instance.client.storage.from('post_images');
      final uploadResult = await storage.upload(fileName, file);

      // Get the public URL of the uploaded image
      final fileUrl = storage.getPublicUrl(fileName); // Directly get the URL string

      // Fetch the current user's username
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final username = currentUserData['username'] ?? 'User';
      final profilePicture = currentUserData['profilePicture'] ?? '';

      // Store the post information in Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'ownerId': FirebaseAuth.instance.currentUser!.uid,
        'username': username,
        'profilePicture': profilePicture,
        'location': viewModel.locationTEC.text,
        'description': viewModel.description,
        'mediaUrl': fileUrl, // Store the image URL in Firestore
        'timestamp': Timestamp.now(),
      });

      // Reset the fields after successful post
      setState(() {
        viewModel.mediaUrl = null; // Reset media URL
        viewModel.description = ''; // Reset description
        viewModel.locationTEC.clear(); // Clear location
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post uploaded successfully')));
    } catch (e) {
      setState(() {
        viewModel.loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload post: ${e.toString()}')));
    }
  }

}
