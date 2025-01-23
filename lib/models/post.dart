import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  String? id;
  String? postId;
  String? ownerId;
  String? username;
  String? location;
  String? description;
  String? mediaUrl;
  Timestamp? timestamp;

  PostModel({
    this.id,
    this.postId,
    this.ownerId,
    this.location,
    this.description,
    this.mediaUrl,
    this.username,
    this.timestamp,
  });

  PostModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    postId = json['postId'];
    ownerId = json['ownerId'];
    location = json['location'];
    username = json['username'];
    description = json['description'];
    mediaUrl = json['mediaUrl'];
    timestamp = json['timestamp'] != null ? json['timestamp'] as Timestamp : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'ownerId': ownerId,
      'username': username,
      'location': location,
      'description': description,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp,
    };
  }
}
