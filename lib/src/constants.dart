import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Light colors ──
  static const Color primary = Color(0xFF0095F6);
  static const Color primaryDark = Color(0xFF1877F2);
  static const Color error = Color(0xFFED4956);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFDBDBDB);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF8E8E8E);

  // ── Dark colors ──
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA8A8A8);

  // ── Theme-independent ──
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
  static const String signupTagline =
      'Sign up to see photos and videos\nfrom your friends.';
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
  static const String passwordTooShort =
      'Password must be at least 6 characters.';

  // Home
  static const String home = 'Home';
  static const String feedComingSoon = 'Feed coming in the next step';

  // Account
  static const String logout = 'Log out';
  static const String changePassword = 'Change Password';
  static const String logoutTitle = 'Log out?';
  static const String logoutConfirm =
      'You will need to log in again to access your account.';
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

class FilterPreset {
  const FilterPreset(this.name, this.matrix, this.rawMatrix);

  final String name;
  final ColorFilter matrix;
  final List<double> rawMatrix;
}

class AppFilters {
  static const List<FilterPreset> presets = [
    FilterPreset(
      'Normal',
      ColorFilter.matrix([
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      'Clarendon',
      ColorFilter.matrix([
        1.25,
        0,
        0,
        0,
        -18,
        0,
        1.25,
        0,
        0,
        -18,
        0,
        0,
        1.25,
        0,
        -28,
        0,
        0,
        0,
        1,
        0,
      ]),
      [
        1.25,
        0,
        0,
        0,
        -18,
        0,
        1.25,
        0,
        0,
        -18,
        0,
        0,
        1.25,
        0,
        -28,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterPreset(
      'Gingham',
      ColorFilter.matrix([
        0.86,
        0.07,
        0.07,
        0,
        0,
        0.07,
        0.86,
        0.07,
        0,
        0,
        0.07,
        0.07,
        0.86,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      [
        0.86,
        0.07,
        0.07,
        0,
        0,
        0.07,
        0.86,
        0.07,
        0,
        0,
        0.07,
        0.07,
        0.86,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterPreset(
      'Moon',
      ColorFilter.matrix([
        0.21,
        0.72,
        0.07,
        0,
        40,
        0.21,
        0.72,
        0.07,
        0,
        40,
        0.21,
        0.72,
        0.07,
        0,
        40,
        0,
        0,
        0,
        1,
        0,
      ]),
      [
        0.21,
        0.72,
        0.07,
        0,
        40,
        0.21,
        0.72,
        0.07,
        0,
        40,
        0.21,
        0.72,
        0.07,
        0,
        40,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterPreset(
      'Lark',
      ColorFilter.matrix([
        1.1,
        0,
        0,
        0,
        15,
        0,
        1.05,
        0,
        0,
        15,
        0,
        0,
        1.0,
        0,
        20,
        0,
        0,
        0,
        1,
        0,
      ]),
      [1.1, 0, 0, 0, 15, 0, 1.05, 0, 0, 15, 0, 0, 1.0, 0, 20, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      'Reyes',
      ColorFilter.matrix([
        1.2,
        0,
        0,
        0,
        0,
        0,
        1.05,
        0,
        0,
        0,
        0,
        0,
        0.9,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      [1.2, 0, 0, 0, 0, 0, 1.05, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      'Juno',
      ColorFilter.matrix([
        1.4,
        0,
        0,
        0,
        -15,
        0,
        1.2,
        0,
        0,
        -10,
        0,
        0,
        1.1,
        0,
        -10,
        0,
        0,
        0,
        1,
        0,
      ]),
      [1.4, 0, 0, 0, -15, 0, 1.2, 0, 0, -10, 0, 0, 1.1, 0, -10, 0, 0, 0, 1, 0],
    ),
    FilterPreset(
      'Willow',
      ColorFilter.matrix([
        0.5,
        0.5,
        0,
        0,
        20,
        0.35,
        0.65,
        0,
        0,
        15,
        0.4,
        0.4,
        0.2,
        0,
        10,
        0,
        0,
        0,
        1,
        0,
      ]),
      [
        0.5,
        0.5,
        0,
        0,
        20,
        0.35,
        0.65,
        0,
        0,
        15,
        0.4,
        0.4,
        0.2,
        0,
        10,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterPreset(
      'Retro CRT',
      ColorFilter.matrix([
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    ),
  ];

  static List<double> brightnessMatrix(double value) {
    final translation = value * 255.0;
    return [
      1,
      0,
      0,
      0,
      translation,
      0,
      1,
      0,
      0,
      translation,
      0,
      0,
      1,
      0,
      translation,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> contrastMatrix(double value) {
    final scale = value;
    final translate = 128.0 * (1.0 - scale);
    return [
      scale,
      0,
      0,
      0,
      translate,
      0,
      scale,
      0,
      0,
      translate,
      0,
      0,
      scale,
      0,
      translate,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> saturationMatrix(double value) {
    final invSat = 1.0 - value;
    final r = 0.213 * invSat;
    final g = 0.715 * invSat;
    final b = 0.072 * invSat;
    return [
      r + value,
      g,
      b,
      0,
      0,
      r,
      g + value,
      b,
      0,
      0,
      r,
      g,
      b + value,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> multiplyMatrices(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) {
          sum += a[i * 5 + 4];
        }
        out[i * 5 + j] = sum;
      }
    }
    return out;
  }

  static ColorFilter getCombinedFilter(
    int filterIndex,
    double brightness,
    double contrast,
    double saturation,
  ) {
    final idx = filterIndex.clamp(0, presets.length - 1);
    List<double> combined = List<double>.from(presets[idx].rawMatrix);
    if (brightness != 0.0) {
      combined = multiplyMatrices(brightnessMatrix(brightness), combined);
    }
    if (contrast != 1.0) {
      combined = multiplyMatrices(contrastMatrix(contrast), combined);
    }
    if (saturation != 1.0) {
      combined = multiplyMatrices(saturationMatrix(saturation), combined);
    }
    return ColorFilter.matrix(combined);
  }
}
