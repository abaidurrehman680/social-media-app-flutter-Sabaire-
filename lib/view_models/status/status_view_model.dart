import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social/models/message.dart';
import 'package:social/models/status.dart';
import 'package:social/models/story_model.dart';
import 'package:social/models/user.dart';
import 'package:social/posts/story/confrim_status.dart';
import 'package:social/services/post_service.dart';
import 'package:social/services/status_services.dart';
import 'package:social/services/user_service.dart';
import 'package:social/utils/constants.dart';
import 'package:social/utils/firebase.dart';

class StatusViewModel extends ChangeNotifier {
  // Services
  UserService userService = UserService();
  PostService postService = PostService();
  StatusService statusService = StatusService();

  // Keys
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Variables
  bool loading = false;
  String? username;
  File? mediaUrl;
  final picker = ImagePicker();
  String? description;
  String? email;
  String? userDp;
  String? userId;
  String? imgLink;
  bool edit = false;
  String? id;

  // Integers
  int pageIndex = 0;

  setDescription(String val) {
    print('SetDescription $val');
    description = val;
    notifyListeners();
  }

  // Functions
  pickImage({bool camera = false, BuildContext? context}) async {
    loading = true;
    notifyListeners();
    try {
      // Pick an image either from the camera or gallery
      XFile? pickedFile = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      );

      // Check if the user picked a file
      if (pickedFile == null) {
        loading = false;
        notifyListeners();
        return;
      }

      // Crop the picked image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        // Aspect ratio presets are handled internally in the latest version
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

      // If cropping was successful, update the mediaUrl
      if (croppedFile != null) {
        mediaUrl = File(croppedFile.path);
        loading = false;
        Navigator.of(context!).push(
          CupertinoPageRoute(
            builder: (_) => ConfirmStatus(),
          ),
        );
      } else {
        showInSnackBar('Crop operation was cancelled.', context);
      }

      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      showInSnackBar('Cancelled', context);
    }
  }

  // Send status message
  sendStatus(String chatId, StatusModel message) {
    statusService.sendStatus(
      message,
      chatId,
    );
  }

  // Send the first status message
  Future<String> sendFirstStatus(StatusModel message) async {
    String newChatId = await statusService.sendFirstStatus(
      message,
    );

    return newChatId;
  }

  resetPost() {
    mediaUrl = null;
    description = null;
    edit = false;
    notifyListeners();
  }

  // Show a snackbar with the provided message
  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
