import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0095F6);
  static const Color primaryDark = Color(0xFF1877F2);
  static const Color error = Color(0xFFED4956);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFDBDBDB);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);

  static const Color storyRingStart = Color(0xFFFEDA75);
  static const Color storyRingOrange = Color(0xFFFA7E1E);
  static const Color storyRingPink = Color(0xFFD62976);
  static const Color storyRingPurple = Color(0xFF962FBF);
  static const Color storyRingBlue = Color(0xFF4F5BD5);

  static const Color storyRingDefault = Color(0xFFC837AB);

  static const Color avatarFallback = Color(0xFFDBDBDB);
  static const Color white = Colors.white;
}

class AppStrings {
  AppStrings._();

  static const String appTitle = 'Instagram Clone';
  static const String appName = 'Instagram';

  // Auth
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String username = 'Username';
  static const String or = 'OR';
  static const String logIn = 'Log In';
  static const String signUp = 'Sign Up';
  static const String logInWithFacebook = 'Log in with Facebook';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Have an account?';
  static const String signupTagline = 'Sign up to see photos and videos\nfrom your friends.';
  static const String signupAgreement =
      'By signing up, you agree to our Terms,\nData Policy and Cookies Policy.';
  static const String demoAccounts = 'Demo accounts';
  static const String facebookLoginMock = 'Mock: Facebook login not wired up.';

  // Validation
  static const String emailRequired = 'Email is required';
  static const String fullNameRequired = 'Full name is required';
  static const String usernameRequired = 'Username is required';
  static const String passwordMinLength = 'Must be at least 6 characters';

  // Auth errors
  static const String fillAllFields = 'Please fill in all fields.';
  static const String invalidEmail = 'Please enter a valid email.';
  static const String wrongCredentials = 'Incorrect email or password.';
  static const String emailAlreadyTaken = 'Email is already registered.';
  static const String usernameAlreadyTaken = 'Username is already taken.';
  static const String passwordTooShort = 'Password must be at least 6 characters.';

  // Home
  static const String home = 'Home';
  static const String feedComingSoon = 'Feed coming in the next step';

  // Account
  static const String logout = 'Log out';
  static const String changePassword = 'Change Password';
  static const String logoutTitle = 'Log out?';
  static const String logoutConfirm = 'You will need to log in again to access your account.';
  static const String deleteAccount = 'Delete account';
  static const String deleteAccountTitle = 'Delete your account?';
  static const String deleteAccountConfirm =
      'This will permanently remove your account and all its data. This action cannot be undone.';
  static const String cancel = 'Cancel';
  static const String done = 'Done';

  // Feed
  static const String forYou = 'For You';
  static const String following = 'Following';
  static const String yourStory = 'Your story';
  static const String likes = 'likes';
  static const String comments = 'Comments';
  static const String noCommentsYet = 'No comments yet. Be the first!';
  static const String addAComment = 'Add a comment...';
  static const String viewAllComments = 'View all comments';

  // Create post
  static const String newPost = 'New post';
  static const String share = 'Share';
  static const String next = 'Next';
  static const String edit = 'Edit';
  static const String takePhoto = 'Take photo';
  static const String writeCaption = 'Write a caption...';
  static const String cameraMock = 'Mock: camera not available.';
}
