import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/src/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('login sets current user', () async {
    final auth = AuthService();
    await auth.init();
    final result = await auth.login('alice@example.com', 'password123');
    expect(result.success, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.currentUser!.username, 'alice');
  });

  test('login with wrong password fails', () async {
    final auth = AuthService();
    await auth.init();
    final result = await auth.login('alice@example.com', 'wrong');
    expect(result.success, isFalse);
    expect(auth.isLoggedIn, isFalse);
  });

  test('session persists across restarts', () async {
    final auth = AuthService();
    await auth.init();
    await auth.login('marco@example.com', 'password123');

    final restored = AuthService();
    await restored.init();
    expect(restored.isLoggedIn, isTrue);
    expect(restored.currentUser!.username, 'marco');
  });

  test('logout clears session', () async {
    final auth = AuthService();
    await auth.init();
    await auth.login('alice@example.com', 'password123');
    await auth.logout();
    expect(auth.isLoggedIn, isFalse);

    final restored = AuthService();
    await restored.init();
    expect(restored.isLoggedIn, isFalse);
  });

  test('signup creates a new account and session', () async {
    final auth = AuthService();
    await auth.init();
    final result = await auth.signup(
      email: 'new@example.com',
      username: 'newbie',
      fullName: 'New User',
      password: 'secret123',
    );
    expect(result.success, isTrue);
    expect(auth.currentUser!.username, 'newbie');

    final restored = AuthService();
    await restored.init();
    expect(restored.isLoggedIn, isTrue);
    expect(restored.currentUser!.email, 'new@example.com');

    final login = await restored.login('new@example.com', 'secret123');
    expect(login.success, isTrue);
  });

  test('delete account removes user and clears session', () async {
    final auth = AuthService();
    await auth.init();
    await auth.signup(
      email: 'doomed@example.com',
      username: 'doomed',
      fullName: 'Doomed User',
      password: 'secret123',
    );
    await auth.deleteAccount();
    expect(auth.isLoggedIn, isFalse);

    final restored = AuthService();
    await restored.init();
    expect(restored.isLoggedIn, isFalse);
    final login = await restored.login('doomed@example.com', 'secret123');
    expect(login.success, isFalse);
  });
}
