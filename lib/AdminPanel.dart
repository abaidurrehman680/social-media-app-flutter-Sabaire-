import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ionicons/ionicons.dart';
import 'package:social/landing/landing_page.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> users = [];
  List<DocumentSnapshot> polls = [];
  bool isLoadingUsers = true;
  bool isLoadingPolls = true;

  TextEditingController pollQuestionController = TextEditingController();
  TextEditingController pollOption1Controller = TextEditingController();
  TextEditingController pollOption2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchPolls();
  }

  // Fetch users from Firestore
  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        users = snapshot.docs;
        isLoadingUsers = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        isLoadingUsers = false;
      });
    }
  }

  // Fetch polls from Firestore
  Future<void> fetchPolls() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('polls').get();
      setState(() {
        polls = snapshot.docs;
        isLoadingPolls = false;
      });
    } catch (e) {
      print("Error fetching polls: $e");
      setState(() {
        isLoadingPolls = false;
      });
    }
  }

  // Create a new poll in Firestore
  Future<void> createPoll(String question, String option1, String option2) async {
    try {
      var pollId = _firestore.collection('polls').doc().id;
      var pollData = {
        'question': question,
        'options': [option1, option2],
        'votes': {option1: 0, option2: 0},
        'voters': [],
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('polls').doc(pollId).set(pollData);
      fetchPolls(); // Refresh poll list after creating a poll
    } catch (e) {
      print("Error creating poll: $e");
    }
  }

  // Delete poll from Firestore
  Future<void> deletePoll(String pollId) async {
    try {
      await _firestore.collection('polls').doc(pollId).delete();
      setState(() {
        polls.removeWhere((poll) => poll.id == pollId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Poll deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting poll")));
    }
  }

  // Build poll card
  Widget buildPollCard(DocumentSnapshot poll) {
    var pollData = poll.data() as Map<String, dynamic>;
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      child: ListTile(
        leading: Icon(Ionicons.checkbox),
        title: Text(pollData['question'] ?? 'No question'),
        subtitle: Text("Options: ${pollData['options']}"),
        trailing: IconButton(
          icon: Icon(Ionicons.trash_outline, color: Colors.red),
          onPressed: () => deletePoll(poll.id),
        ),
      ),
    );
  }

  // Build user card
  Widget buildUserCard(DocumentSnapshot user) {
    var userData = user.data() as Map<String, dynamic>;

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: userData['profilePicture'] != null && userData['profilePicture'].isNotEmpty
              ? NetworkImage(userData['profilePicture'])
              : AssetImage('assets/default_user.png') as ImageProvider,  // Use asset image if no profile picture
          radius: 30,
        ),
        title: Text(userData['username'] ?? 'Unknown'),
        subtitle: Text(userData['email'] ?? 'No email'),
        trailing: IconButton(
          icon: Icon(Ionicons.trash_outline, color: Colors.red),
          onPressed: () => deleteUser(user.id),
        ),
      ),
    );
  }

  // Delete user from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      setState(() {
        users.removeWhere((user) => user.id == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting user")));
    }
  }

  // Search users functionality
  List<DocumentSnapshot> searchUsers(String query) {
    return users.where((user) {
      var userData = user.data() as Map<String, dynamic>;
      return userData['username'].toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Ionicons.chevron_back_outline),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Landing()), // Replace with your landing page widget
                  (Route<dynamic> route) => false, // Remove all the previous routes
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Ionicons.log_out_outline),
            onPressed: () {
              _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Landing()), // Replace with your landing page widget
                    (Route<dynamic> route) => false, // Remove all the previous routes
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Polls section
            isLoadingPolls
                ? CircularProgressIndicator()
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Polls",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Create New Poll"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: pollQuestionController,
                                decoration: InputDecoration(hintText: "Poll Question"),
                              ),
                              TextField(
                                controller: pollOption1Controller,
                                decoration: InputDecoration(hintText: "Option 1"),
                              ),
                              TextField(
                                controller: pollOption2Controller,
                                decoration: InputDecoration(hintText: "Option 2"),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                createPoll(
                                  pollQuestionController.text,
                                  pollOption1Controller.text,
                                  pollOption2Controller.text,
                                );
                                Navigator.pop(context);
                              },
                              child: Text("Create Poll"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text("Create Poll", style: TextStyle(fontSize: 18)),
                ),
                ...polls.map(buildPollCard),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewPostsPage(),
                    ),
                  );
                },
                child: Text("View All Posts", style: TextStyle(fontSize: 18)),
              ),
            ),
            Divider(),
            // Users section
            isLoadingUsers
                ? CircularProgressIndicator()
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Users",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search users...",
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                ...searchUsers("").map(buildUserCard), // Pass an empty string to show all users
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ViewPostsPage extends StatefulWidget {
  @override
  _ViewPostsPageState createState() => _ViewPostsPageState();
}

class _ViewPostsPageState extends State<ViewPostsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> posts = [];
  bool isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('posts').get();
      setState(() {
        posts = snapshot.docs;
        isLoadingPosts = false;
      });
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      setState(() {
        posts.removeWhere((post) => post.id == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Post deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting post")));
    }
  }

  Widget buildPostCard(DocumentSnapshot post) {
    var postData = post.data() as Map<String, dynamic>;

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      child: ListTile(
        leading: Icon(Ionicons.document_text),
        title: Text(postData['content'] ?? 'No content'),
        subtitle: Text(postData['timestamp']?.toDate().toString() ?? 'No date'),
        trailing: IconButton(
          icon: Icon(Ionicons.trash_outline, color: Colors.red),
          onPressed: () => deletePost(post.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Posts"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            isLoadingPosts
                ? CircularProgressIndicator()
                : Column(
              children: posts.map(buildPostCard).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
