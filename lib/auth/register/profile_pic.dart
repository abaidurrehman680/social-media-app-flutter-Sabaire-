import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social/services/auth_service.dart';
import 'package:social/auth/login/login.dart';  // Import the login page
import 'package:social/view_models/auth/posts_view_model.dart';
import 'package:social/widgets/indicators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../components/custom_image.dart';

class ProfilePicture extends StatefulWidget {
  @override
  _ProfilePictureState createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  @override
  Widget build(BuildContext context) {
    PostsViewModel viewModel = Provider.of<PostsViewModel>(context);
    return WillPopScope(
      onWillPop: () async {
        viewModel.resetPost();
        return true;
      },
      child: LoadingOverlay(
        progressIndicator: circularProgress(context),
        isLoading: viewModel.loading,
        child: Scaffold(
          key: viewModel.scaffoldKey,
          appBar: AppBar(
            title: Text('Add a profile picture'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            children: [
              InkWell(
                onTap: () => showImageChoices(context, viewModel),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width - 30,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(
                      Radius.circular(3.0),
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
                      'Tap to add your profile picture',
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
              SizedBox(height: 10.0),
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).colorScheme.secondary),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text('done'.toUpperCase()),
                    ),
                  ),
                  onPressed: () => uploadProfilePicture(context, viewModel),
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
                  'Select from'.toUpperCase(),
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

  Future<void> uploadProfilePicture(BuildContext context,
      PostsViewModel viewModel) async {
    if (viewModel.mediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image first')));
      return;
    }

    setState(() {
      viewModel.loading = true;
    });

    try {
      final file = viewModel.mediaUrl!;
      final fileName = 'profile/${DateTime.now().millisecondsSinceEpoch}.png';

      final storage = supabase.Supabase.instance.client.storage.from('profile');
      final uploadResult = await storage.upload(fileName, file);

      final fileUrlResult = storage.getPublicUrl(fileName);

      final imageUrl = fileUrlResult;

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePicture': imageUrl,
        });
      }

      setState(() {
        viewModel.imgLink = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')));

      // After profile picture upload, navigate to login page
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => Login()),  // Navigate to Login screen after success
      );
    } catch (e) {
      setState(() {
        viewModel.loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}')));
    }
  }
}
