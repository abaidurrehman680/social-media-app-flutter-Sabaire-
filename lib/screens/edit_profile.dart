import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social/components/text_form_builder.dart';
import 'package:social/models/user.dart';
import 'package:social/utils/firebase.dart';
import 'package:social/utils/validation.dart';
import 'package:social/view_models/profile/edit_profile_view_model.dart';
import 'package:social/widgets/indicators.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfile extends StatefulWidget {
  final UserModel? user;

  const EditProfile({this.user});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  String? selectedImageUrl;

  String currentUid() {
    return firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _uploadProfileImage(EditProfileViewModel viewModel) async {
    if (viewModel.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image first')));
      return;
    }

    // setState(() {
    //   viewModel.loading = true;
    // });

    try {
      final file = viewModel.image!;  // The selected image file
      final fileName = 'profile/${DateTime.now().millisecondsSinceEpoch}.jpg';  // Unique file name
      final storage = Supabase.instance.client.storage.from('profile');  // Access the Supabase profile bucket

      // Upload the image to Supabase storage
      final uploadResult = await storage.upload(fileName, file);


      // Get the public URL of the uploaded image
      final fileUrlResult = storage.getPublicUrl(fileName);

      final imageUrl = fileUrlResult;  // The URL of the uploaded image

      // Get the current Firebase user
      firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update the Firestore `profilePicture` field with the new image URL
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePicture': imageUrl,  // Save the image URL to Firestore
        });

        setState(() {
          selectedImageUrl = imageUrl;  // Update the image URL in the UI
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture updated successfully')));
    } catch (e) {
      setState(() {
        viewModel.loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile picture: ${e.toString()}')));
    }
  }

  // Save user data without navigating away
  Future<void> _saveProfileData(EditProfileViewModel viewModel) async {
    try {
      firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the current user's document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        // Get the current values from Firestore
        String currentUsername = userDoc['username'] ?? '';
        String currentCountry = userDoc['country'] ?? '';
        String currentBio = userDoc['bio'] ?? '';

        // Only update values that have changed
        Map<String, dynamic> updatedData = {};

        // Check if the value is not null and not empty
        if (viewModel.username != currentUsername && (viewModel.username?.isNotEmpty ?? false)) {
          updatedData['username'] = viewModel.username;
        }
        if (viewModel.country != currentCountry && (viewModel.country?.isNotEmpty ?? false)) {
          updatedData['country'] = viewModel.country;
        }
        if (viewModel.bio != currentBio && (viewModel.bio?.isNotEmpty ?? false)) {
          updatedData['bio'] = viewModel.bio;
        }

        // If there is any updated data, apply the changes to Firestore
        if (updatedData.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedData);
        }

        // Upload the profile image if selected
        await _uploadProfileImage(viewModel);

        // Stay on the current page
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile data: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    EditProfileViewModel viewModel = Provider.of<EditProfileViewModel>(context);
    return LoadingOverlay(
      progressIndicator: circularProgress(context),
      isLoading: viewModel.loading,
      child: Scaffold(
        key: viewModel.scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: Text("Edit Profile"),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 25.0),
                child: GestureDetector(
                  onTap: () {
                    // Save the profile changes and stay on the same page
                    _saveProfileData(viewModel);  // Save user data
                  },
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: () => viewModel.pickImage(context: context), // Pass context here
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        offset: Offset(0.0, 0.0),
                        blurRadius: 2.0,
                      ),
                    ],
                  ),
                  child: viewModel.imgLink != null
                      ? Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: CircleAvatar(
                      radius: 65.0,
                      backgroundImage: NetworkImage(viewModel.imgLink!),
                    ),
                  )
                      : viewModel.image == null
                      ? Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: CircleAvatar(
                      radius: 65.0,
                      backgroundImage: NetworkImage(widget.user!.profilePicture!),
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: CircleAvatar(
                      radius: 65.0,
                      backgroundImage: FileImage(viewModel.image!),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            buildForm(viewModel, context)
          ],
        ),
      ),
    );
  }

  buildForm(EditProfileViewModel viewModel, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: viewModel.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextFormBuilder(
              enabled: !viewModel.loading,
              initialValue: widget.user!.username,
              prefix: Ionicons.person_outline,
              hintText: "Username",
              textInputAction: TextInputAction.next,
              validateFunction: Validations.validateName,
              onSaved: (String val) {
                viewModel.setUsername(val);
              },
            ),
            SizedBox(height: 10.0),
            TextFormBuilder(
              initialValue: widget.user!.country,
              enabled: !viewModel.loading,
              prefix: Ionicons.pin_outline,
              hintText: "Country",
              textInputAction: TextInputAction.next,
              validateFunction: Validations.validateName,
              onSaved: (String val) {
                viewModel.setCountry(val);
              },
            ),
            SizedBox(height: 10.0),
            Text(
              "Bio",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextFormField(
              maxLines: null,
              initialValue: widget.user!.bio,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (String? value) {
                if (value!.length > 1000) {
                  return 'Bio must be short';
                }
                return null;
              },
              onSaved: (String? val) {
                viewModel.setBio(val!);
              },
              onChanged: (String val) {
                viewModel.setBio(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
