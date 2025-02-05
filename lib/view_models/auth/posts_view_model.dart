import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:social/models/post.dart';
import 'package:social/screens/mainscreen.dart';
import 'package:social/services/post_service.dart';
import 'package:social/services/user_service.dart';
import 'package:social/utils/constants.dart';
import 'package:social/utils/firebase.dart';

class PostsViewModel extends ChangeNotifier {
  // Services
  UserService userService = UserService();
  PostService postService = PostService();

  // Keys
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Variables
  bool loading = false;
  String? username;
  File? mediaUrl;
  final picker = ImagePicker();
  String? location;
  Position? position;
  Placemark? placemark;
  String? bio;
  String? description;
  String? email;
  String? commentData;
  String? ownerId;
  String? userId;
  String? type;
  File? userDp;
  String? imgLink;
  bool edit = false;
  String? id;

  // Controllers
  TextEditingController locationTEC = TextEditingController();

  // Setters
  setEdit(bool val) {
    edit = val;
    notifyListeners();
  }

  setPost(PostModel post) {
    if (post != null) {
      description = post.description;
      imgLink = post.mediaUrl;
      location = post.location;
      edit = true;
      edit = false;
      notifyListeners();
    } else {
      edit = false;
      notifyListeners();
    }
  }

  setUsername(String val) {
    print('SetName $val');
    username = val;
    notifyListeners();
  }

  setDescription(String val) {
    print('SetDescription $val');
    description = val;
    notifyListeners();
  }

  setLocation(String val) {
    print('SetCountry $val');
    location = val;
    notifyListeners();
  }

  setBio(String val) {
    print('SetBio $val');
    bio = val;
    notifyListeners();
  }

  // Functions
  pickImage({bool camera = false, BuildContext? context}) async {
    loading = true;
    notifyListeners();
    try {
      // Pick an image from camera or gallery
      PickedFile? pickedFile = await picker.getImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile == null) {
        loading = false;
        notifyListeners();
        return;
      }

      // Crop the picked image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
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
        mediaUrl = File(croppedFile.path);
      }

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      if (context != null) {
        showInSnackBar('Cancelled', context!);
      }
    }
  }

  getLocation() async {
    loading = true;
    notifyListeners();
    LocationPermission permission = await Geolocator.checkPermission();
    print(permission);
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission rPermission = await Geolocator.requestPermission();
      print(rPermission);
      await getLocation();
    } else {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position!.latitude, position!.longitude);
      placemark = placemarks[0];
      location = " ${placemarks[0].locality}, ${placemarks[0].country}";
      locationTEC.text = location!;
      print(location);
    }
    loading = false;
    notifyListeners();
  }

  uploadPosts(BuildContext context) async {
    try {
      loading = true;
      notifyListeners();
      await postService.uploadPost(mediaUrl!, location!, description!);
      loading = false;
      resetPost();
      notifyListeners();
    } catch (e) {
      print(e);
      loading = false;
      resetPost();
      if (context != null) {
        showInSnackBar('Uploaded successfully!', context);
      }
      notifyListeners();
    }
  }

  uploadProfilePicture(BuildContext context) async {
    if (mediaUrl == null) {
      if (context != null) {
        showInSnackBar('Please select an image', context);
      }
    } else {
      try {
        loading = true;
        notifyListeners();
        await postService.uploadProfilePicture(
            mediaUrl!, firebaseAuth.currentUser!);
        loading = false;
        Navigator.of(context)
            .pushReplacement(CupertinoPageRoute(builder: (_) => TabScreen()));
        notifyListeners();
      } catch (e) {
        print(e);
        loading = false;
        if (context != null) {
          showInSnackBar('Uploaded successfully!', context);
        }
        notifyListeners();
      }
    }
  }

  resetPost() {
    mediaUrl = null;
    description = null;
    location = null;
    edit = false;
    notifyListeners();
  }

  void showInSnackBar(String value, BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
