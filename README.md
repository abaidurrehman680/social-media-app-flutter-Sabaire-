Sabaire - Social Media Platform
Sabaire is a feature-rich social media platform designed to foster meaningful interactions between users, offering a seamless blend of social features, real-time messaging, and user engagement. The app allows users to create profiles, post content, interact with others through likes, comments, and follows, and stay connected through real-time notifications and private chats.

Key Features:
User Authentication: Secure login and registration using Firebase Authentication.
Profile Management: Customizable user profiles with editable bios, profile pictures, and post history.
Post Creation: Users can upload posts with text, images, and locations. Posts are easily shareable and can be liked or commented on.
Real-Time Chat: Instant messaging with real-time notifications for new messages and interactions.
Notifications: Push notifications for likes, comments, follows, and new messages, ensuring users stay up-to-date with interactions.
Admin Panel: Admins can manage user accounts, moderate posts, and create or delete polls.
Integration with Firebase and Supabase: Firebase for user authentication, storage, and Firestore for real-time data management, with Supabase used for handling status updates and media storage.
Backend:
Firebase: Used for user authentication, Firestore (database) for posts, comments, likes, and notifications, and Firebase Storage for media file handling.
Supabase: Handles real-time features, including status updates and media storage for scalable backend operations.
Tech Stack:
Frontend: Flutter (Dart) for building a responsive and interactive mobile app interface.
Backend: Firebase for storage, authentication, and real-time database management, Supabase for extended real-time capabilities.

Navigate into the project directory:
cd sabaire-app

Install dependencies:
flutter pub get

Run the app:
flutter run

Contributing:
Contributions are welcome! If you'd like to contribute to this project, feel free to fork the repository and submit pull requests. Please ensure that your code adheres to the project's code style guidelines and includes tests for any new features.
