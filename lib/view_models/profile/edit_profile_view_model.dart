import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social/models/user.dart';
import 'package:social/services/user_service.dart';
import 'package:social/utils/constants.dart';

class EditProfileViewModel extends ChangeNotifier {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool validate = false;
  bool loading = false;
  UserService userService = UserService();
  final picker = ImagePicker();
  UserModel? user;
  String? country;
  String? username;
  String? bio;
  File? image;
  String? imgLink;

  // Set user data
  setUser(UserModel val) {
    user = val;
    notifyListeners();
  }

  // Set image link
  setImage(UserModel user) {
    imgLink = user.profilePicture;
  }

  // Set country
  setCountry(String val) {
    print('SetCountry $val');
    country = val;
    notifyListeners();
  }

  // Set bio
  setBio(String val) {
    print('SetBio$val');
    bio = val;
    notifyListeners();
  }

  // Set username
  setUsername(String val) {
    print('SetUsername$val');
    username = val;
    notifyListeners();
  }

  // Edit profile logic
  editProfile(BuildContext context) async {
    FormState form = formKey.currentState!;
    form.save();
    if (!form.validate()) {
      validate = true;
      notifyListeners();
      showInSnackBar(
          'Please fix the errors in red before submitting.', context);
    } else {
      try {
        loading = true;
        notifyListeners();
        bool success = await userService.updateProfile(
          image: image,
          username: username,
          bio: bio,
          country: country,
        );
        print(success);
        if (success) {
          clear();
          Navigator.pop(context);
        }
      } catch (e) {
        loading = false;
        notifyListeners();
        print(e);
      }
      loading = false;
      notifyListeners();
    }
  }

  // Pick an image from gallery or camera
  pickImage({bool camera = false, required BuildContext context}) async {
    loading = true;
    notifyListeners();
    try {
      PickedFile? pickedFile = await picker.getImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      );

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0), // Example aspect ratio for a square
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Constants.lightAccent,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              minimumAspectRatio: 1.0,
            ),
          ],
        );
        if (croppedFile != null) {
          image = File(croppedFile.path);
        }
      }
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      showInSnackBar('Cancelled', context);
    }
  }

  // Clear the image data
  clear() {
    image = null;
    notifyListeners();
  }

  // Show snackbar with a message
  void showInSnackBar(String value, BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
