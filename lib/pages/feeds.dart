import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:social/pages/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../chats/recent_chats.dart';
import '../screens/comment.dart';

class Feeds extends StatefulWidget {
  @override
  _FeedsState createState() => _FeedsState();
}

class _FeedsState extends State<Feeds> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> posts = [];
  bool isLoading = false;
  bool hasMore = true;
  int pageSize = 5;

  // Poll Variables
  String? selectedPollOption;
  String? selectedPollId; // Track which poll is selected

  @override
  void initState() {
    super.initState();
    fetchPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && hasMore) {
        fetchPosts();
      }
    });
  }

  Future<void> fetchPosts() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    if (posts.isNotEmpty) {
      query = query.startAfterDocument(posts.last);
    }

    QuerySnapshot snapshot = await query.get();
    if (snapshot.docs.length < pageSize) {
      setState(() => hasMore = false);
    }

    setState(() {
      posts.addAll(snapshot.docs);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Sabaire', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Ionicons.chatbubble_ellipses, size: 30.0),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => Chats(),
                ),
              );
              // Navigate to chats
            },
          ),
          SizedBox(width: 20.0),
        ],
      ),
      body: SingleChildScrollView(  // Wrap the entire body with SingleChildScrollView
        child: Column(
          children: [
            buildMultipleSections(), // Build multiple sections for feed
            if (isLoading) CircularProgressIndicator(), // Show loading indicator if needed
            Column(
              children: posts.map((post) => buildPost(post)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build multiple sections for different contents
  Widget buildMultipleSections() {
    return Column(
      children: [
        buildTrendingSection(),
        buildPollsSection(),
      ],
    );
  }

  // Trending Section
  Widget buildTrendingSection() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Posts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // Display a list of trending posts (You can customize this)
          for (var post in posts) buildPost(post),
        ],
      ),
    );
  }

  // Polls Section - Interactive Polls
  Widget buildPollsSection() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Polls & Surveys',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // Fetch Poll data from Firebase Firestore and build dynamic poll section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('polls').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text('No poll data available');
              }

              var polls = snapshot.data!.docs;

              return Column(
                children: polls.map((pollDoc) {
                  var pollData = pollDoc.data() as Map<String, dynamic>;
                  List<String> options = List<String>.from(pollData['options']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPollId = pollDoc.id;
                        selectedPollOption = null;  // Reset the option on tap
                      });
                      _showPollDialog(context, options, pollData['votes'], pollDoc.id);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(pollData['question'], style: TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Poll dialog with options and results
  void _showPollDialog(BuildContext context, List<String> options, Map<String, dynamic> votes, String pollId) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Poll Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var option in options)
                ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: selectedPollOption,
                    onChanged: (String? value) {
                      setState(() {
                        selectedPollOption = value;
                      });
                      _handlePollVote(userId, pollId, value!);
                      Navigator.pop(context);
                    },
                  ),
                ),
              // Display poll results dynamically
              SizedBox(height: 20),
              Text("Poll Results:"),
              for (var option in options)
                Text("$option: ${votes[option] ?? 0} votes"),
            ],
          ),
        );
      },
    );
  }

  // Handle Poll Vote (Only allow one vote per user)
  void _handlePollVote(String userId, String pollId, String option) async {
    final pollDocRef = FirebaseFirestore.instance.collection('polls').doc(pollId); // Fetch the specific poll by ID

    // Check if the poll document exists
    var pollDoc = await pollDocRef.get();

    if (pollDoc.exists) {
      // Get current voters list or initialize as an empty array if it doesn't exist
      List<dynamic> voters = pollDoc['voters'] ?? [];

      if (!voters.contains(userId)) {
        // Update poll results by incrementing the selected option's vote count
        await pollDocRef.update({
          'votes.$option': FieldValue.increment(1),  // Increment the vote count for the selected option
          'voters': FieldValue.arrayUnion([userId]),  // Add the user ID to the voters list to prevent multiple votes
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your vote has been recorded!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can only vote once!')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Poll not found!')));
    }
  }


  // Post Widget for Feed
  // Post Widget for Feed
  // Post Widget for Feed
  Widget buildPost(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    List<dynamic> likes = (data['likes'] is List) ? data['likes'] : [];
    String postId = post.id;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(data['ownerId']).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (userSnapshot.hasData && userSnapshot.data != null) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;

          return Card(
            margin: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      // Navigate to the user's profile
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => Profile(profileId: data['ownerId']),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: userData['profilePicture'] != null && userData['profilePicture'].isNotEmpty
                          ? NetworkImage(userData['profilePicture'])
                          : AssetImage('assets/default_user.png') as ImageProvider,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      // Navigate to the user's profile
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => Profile(profileId: data['ownerId']),
                        ),
                      );
                    },
                    child: Text(userData['username'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  subtitle: Text(timeago.format((data['timestamp'] as Timestamp).toDate())),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to view full image or post details
                  },
                  child: Image.network(
                    data['mediaUrl'] ?? '',
                    width: double.infinity,
                    height: 250.0,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                  child: Row(
                    children: [
                      LikeButton(
                        size: 25.0,
                        isLiked: likes.contains(FirebaseAuth.instance.currentUser!.uid),
                        onTap: (isLiked) async {
                          final likeRef = FirebaseFirestore.instance.collection('likes').doc('${post.id}_${FirebaseAuth.instance.currentUser!.uid}');
                          if (isLiked) {
                            await likeRef.delete();
                            await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
                              'likes': FieldValue.arrayRemove([FirebaseAuth.instance.currentUser!.uid]),
                            });
                          } else {
                            await likeRef.set({
                              'postId': post.id,
                              'userId': FirebaseAuth.instance.currentUser!.uid,
                              'timestamp': Timestamp.now(),
                            });
                            await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
                              'likes': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]),
                            });
                          }
                          return !isLiked;
                        },
                        likeCount: likes.length,
                        likeBuilder: (bool isLiked) {
                          return Icon(
                            isLiked ? Ionicons.heart : Ionicons.heart_outline,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 25.0,
                          );
                        },
                      ),
                      SizedBox(width: 10.0),
                      IconButton(
                        icon: Icon(Ionicons.chatbubble_outline),
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => Comments(
                                postId: post.id,
                                ownerId: data['ownerId'] ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                      // Display the comment count dynamically
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('comments')
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (!commentSnapshot.hasData) {
                            return Text("comments", style: TextStyle(fontSize: 14.0));
                          }
                          int commentCount = commentSnapshot.data!.docs.length;
                          return Text("comments", style: TextStyle(fontSize: 14.0));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox();
      },
    );
  }



  @override
  bool get wantKeepAlive => true;
}
