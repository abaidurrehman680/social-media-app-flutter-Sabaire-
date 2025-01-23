import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social/models/comments.dart';
import 'package:social/models/user.dart';
import 'package:social/services/post_service.dart';
import 'package:social/utils/firebase.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId; // Required postId
  final String ownerId; // Required ownerId

  Comments({Key? key, required this.postId, required this.ownerId}) : super(key: key);

  @override
  _CommentsState createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  UserModel? user;

  PostService services = PostService();
  final DateTime timestamp = DateTime.now();
  TextEditingController commentsTEC = TextEditingController();

  String currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.xmark_circle_fill),
        ),
        centerTitle: true,
        title: Text('Comments'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Expanded(child: buildComments()),
            buildCommentInputField(),
          ],
        ),
      ),
    );
  }

  Widget buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: commentRef
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        int commentCount = snapshot.data!.docs.length;

        return Column(
          children: [
            // Displaying the comment count
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "$commentCount comments",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
            // Displaying the actual list of comments
            ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var comment = CommentModel.fromJson(snapshot.data!.docs[index].data() as Map<String, dynamic>);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(currentUserId()).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    var currentUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                    String userProfilePic = currentUserData['profilePicture'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userProfilePic.isNotEmpty
                            ? CachedNetworkImageProvider(userProfilePic)
                            : AssetImage('assets/default_user.png') as ImageProvider,
                      ),
                      title: Text(comment.username ?? ''),
                      subtitle: Text(comment.comment ?? ''),
                      trailing: Text(timeago.format(comment.timestamp!.toDate())),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }



  Widget buildCommentInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentsTEC,
              decoration: InputDecoration(
                hintText: "Write your comment...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              if (commentsTEC.text.trim().isNotEmpty) {
                await services.uploadComment(
                  currentUserId(),
                  commentsTEC.text.trim(),
                  widget.postId,
                  widget.ownerId,
                  '', // Provide a default value or handle null for `mediaUrl`
                );
                commentsTEC.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
