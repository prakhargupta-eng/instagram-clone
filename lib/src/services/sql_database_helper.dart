import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/story.dart';

class SqlDatabaseHelper {
  static final SqlDatabaseHelper instance = SqlDatabaseHelper._init();
  static Database? _database;
  static bool isTesting = false;

  SqlDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('instagram_clone.db');
    return _database!;
  }

  /// Closes and forgets the cached database so tests start fresh.
  Future<void> closeForTesting() async {
    final db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (isTesting) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: _createDB,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _cleanExistingVideoUrls(db);
      },
    );
  }

  Future<void> _cleanExistingVideoUrls(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query('posts');
      for (final map in maps) {
        final String videoUrl = map['videoUrl'] as String? ?? '';
        final String imageUrl = map['imageUrl'] as String? ?? '';

        bool needsUpdate = false;
        final updatedMap = <String, dynamic>{};

        if (videoUrl.contains('?') || videoUrl.startsWith('file://')) {
          var cleanVideoUrl = videoUrl;
          if (cleanVideoUrl.contains('?')) {
            cleanVideoUrl = cleanVideoUrl.split('?').first;
          }
          if (cleanVideoUrl.startsWith('file://')) {
            try {
              cleanVideoUrl = Uri.parse(cleanVideoUrl).toFilePath();
            } catch (_) {}
          }
          updatedMap['videoUrl'] = cleanVideoUrl;
          needsUpdate = true;
        }

        if (imageUrl.contains('?') || imageUrl.startsWith('file://')) {
          var cleanImageUrl = imageUrl;
          if (cleanImageUrl.contains('?')) {
            cleanImageUrl = cleanImageUrl.split('?').first;
          }
          if (cleanImageUrl.startsWith('file://')) {
            try {
              cleanImageUrl = Uri.parse(cleanImageUrl).toFilePath();
            } catch (_) {}
          }
          updatedMap['imageUrl'] = cleanImageUrl;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await db.update(
            'posts',
            updatedMap,
            where: 'id = ?',
            whereArgs: [map['id']],
          );
        }
      }
    } catch (e) {
      print('Error cleaning existing video URLs: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE posts ADD COLUMN filterIndex INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE posts ADD COLUMN brightness REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE posts ADD COLUMN contrast REAL DEFAULT 1.0',
      );
      await db.execute(
        'ALTER TABLE posts ADD COLUMN saturation REAL DEFAULT 1.0',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL,
        bio TEXT,
        avatarUrl TEXT,
        following INTEGER DEFAULT 0,
        followers INTEGER DEFAULT 0,
        isPrivate INTEGER DEFAULT 0,
        website TEXT,
        gender TEXT
      )
    ''');

    // 2. Credentials table
    await db.execute('''
      CREATE TABLE credentials (
        email TEXT PRIMARY KEY,
        password TEXT NOT NULL
      )
    ''');

    // 3. Session table
    await db.execute('''
      CREATE TABLE session (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL
      )
    ''');

    // 4. Posts table
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        videoUrl TEXT NOT NULL,
        caption TEXT NOT NULL,
        location TEXT,
        music TEXT,
        musicPreviewUrl TEXT,
        createdAt TEXT NOT NULL,
        isVideo INTEGER DEFAULT 0,
        filterIndex INTEGER DEFAULT 0,
        brightness REAL DEFAULT 0.0,
        contrast REAL DEFAULT 1.0,
        saturation REAL DEFAULT 1.0
      )
    ''');

    // 5. Likes table
    await db.execute('''
      CREATE TABLE likes (
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        PRIMARY KEY (post_id, user_id)
      )
    ''');

    // 6. Comments table
    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 7. Stories table
    await db.execute('''
      CREATE TABLE stories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        isVideo INTEGER DEFAULT 0,
        durationSeconds INTEGER DEFAULT 5,
        createdAt TEXT NOT NULL
      )
    ''');

    // 8. Follows table
    await db.execute('''
      CREATE TABLE follows (
        follower_id TEXT NOT NULL,
        following_id TEXT NOT NULL,
        PRIMARY KEY (follower_id, following_id)
      )
    ''');

    // 9. Local posts table
    await db.execute('''
      CREATE TABLE local_posts (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        videoUrl TEXT NOT NULL,
        caption TEXT NOT NULL,
        location TEXT,
        music TEXT,
        musicPreviewUrl TEXT,
        createdAt TEXT NOT NULL,
        isVideo INTEGER DEFAULT 0
      )
    ''');

    // 10. Watched stories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watched_stories (
        story_id TEXT PRIMARY KEY
      )
    ''');
  }

  // ── User Operations ───────────────────────────────────────────────────────

  Future<void> insertUser(AppUser user) async {
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'fullName': user.fullName,
      'email': user.email,
      'bio': user.bio,
      'avatarUrl': user.avatarUrl,
      'following': user.following,
      'followers': user.followers,
      'isPrivate': user.isPrivate ? 1 : 0,
      'website': user.website,
      'gender': user.gender,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppUser?> getUser(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      final map = maps.first;
      return AppUser(
        id: map['id'] as String,
        username: map['username'] as String,
        fullName: map['fullName'] as String,
        email: map['email'] as String,
        bio: map['bio'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String? ?? '',
        following: map['following'] as int? ?? 0,
        followers: map['followers'] as int? ?? 0,
        isPrivate: (map['isPrivate'] as int? ?? 0) == 1,
        website: map['website'] as String? ?? '',
        gender: map['gender'] as String? ?? '',
      );
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) {
      return AppUser(
        id: map['id'] as String,
        username: map['username'] as String,
        fullName: map['fullName'] as String,
        email: map['email'] as String,
        bio: map['bio'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String? ?? '',
        following: map['following'] as int? ?? 0,
        followers: map['followers'] as int? ?? 0,
        isPrivate: (map['isPrivate'] as int? ?? 0) == 1,
        website: map['website'] as String? ?? '',
        gender: map['gender'] as String? ?? '',
      );
    }).toList();
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ── Credentials Operations ────────────────────────────────────────────────

  Future<void> setPassword(String email, String password) async {
    final db = await database;
    await db.insert('credentials', {
      'email': email.toLowerCase(),
      'password': password,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPassword(String email) async {
    final db = await database;
    final maps = await db.query(
      'credentials',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (maps.isNotEmpty) {
      return maps.first['password'] as String?;
    }
    return null;
  }

  Future<Map<String, String>> getAllCredentials() async {
    final db = await database;
    final maps = await db.query('credentials');
    final Map<String, String> credentials = {};
    for (final map in maps) {
      final email = map['email'] as String?;
      final password = map['password'] as String?;
      if (email != null && password != null) {
        credentials[email] = password;
      }
    }
    return credentials;
  }

  Future<void> deletePassword(String email) async {
    final db = await database;
    await db.delete(
      'credentials',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  // ── Session Operations ────────────────────────────────────────────────────

  Future<void> saveSession(String userId) async {
    final db = await database;
    await db.insert('session', {
      'id': 'current_session',
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSessionUserId() async {
    final db = await database;
    final maps = await db.query(
      'session',
      where: 'id = ?',
      whereArgs: ['current_session'],
    );

    if (maps.isNotEmpty) {
      return maps.first['user_id'] as String?;
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('session', where: 'id = ?', whereArgs: ['current_session']);
  }

  // ── Post Operations ───────────────────────────────────────────────────────

  Future<void> insertPost(Post post) async {
    final db = await database;

    var cleanImageUrl = post.imageUrl;
    if (cleanImageUrl.contains('?')) {
      cleanImageUrl = cleanImageUrl.split('?').first;
    }
    if (cleanImageUrl.startsWith('file://')) {
      try {
        cleanImageUrl = Uri.parse(cleanImageUrl).toFilePath();
      } catch (_) {}
    }

    var cleanVideoUrl = post.videoUrl;
    if (cleanVideoUrl.contains('?')) {
      cleanVideoUrl = cleanVideoUrl.split('?').first;
    }
    if (cleanVideoUrl.startsWith('file://')) {
      try {
        cleanVideoUrl = Uri.parse(cleanVideoUrl).toFilePath();
      } catch (_) {}
    }

    final postMap = {
      'id': post.id,
      'author_id': post.author.id,
      'imageUrl': cleanImageUrl,
      'videoUrl': cleanVideoUrl,
      'caption': post.caption,
      'location': post.location,
      'music': post.music,
      'musicPreviewUrl': post.musicPreviewUrl,
      'createdAt': post.createdAt.toIso8601String(),
      'isVideo': post.isVideo ? 1 : 0,
      'filterIndex': post.filterIndex,
      'brightness': post.brightness,
      'contrast': post.contrast,
      'saturation': post.saturation,
    };
    print('DB Insert Post: $postMap');
    await db.insert(
      'posts',
      postMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await insertUser(post.author);

    await db.delete('likes', where: 'post_id = ?', whereArgs: [post.id]);
    for (final userId in post.likedBy) {
      await db.insert('likes', {
        'post_id': post.id,
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final comment in post.comments) {
      await insertComment(post.id, comment);
    }
  }

  Future<List<Post>> getAllPosts() async {
    final db = await database;
    final postMaps = await db.query('posts', orderBy: 'createdAt DESC');
    print('DB Query posts returned ${postMaps.length} records: $postMaps');

    final List<Post> posts = [];
    for (final map in postMaps) {
      final postId = map['id'] as String;
      final authorId = map['author_id'] as String;
      final author = await getUser(authorId);

      if (author == null) continue;

      final likeMaps = await db.query(
        'likes',
        columns: ['user_id'],
        where: 'post_id = ?',
        whereArgs: [postId],
      );
      final likedBy = likeMaps.map((e) => e['user_id'] as String).toList();

      final comments = await getCommentsForPost(postId);

      posts.add(
        Post(
          id: postId,
          author: author,
          imageUrl: map['imageUrl'] as String? ?? '',
          videoUrl: map['videoUrl'] as String? ?? '',
          caption: map['caption'] as String? ?? '',
          location: map['location'] as String?,
          music: map['music'] as String?,
          musicPreviewUrl: map['musicPreviewUrl'] as String?,
          createdAt: DateTime.parse(map['createdAt'] as String),
          likedBy: likedBy,
          comments: comments,
          isVideo: (map['isVideo'] as int? ?? 0) == 1,
          filterIndex: map['filterIndex'] as int? ?? 0,
          brightness: (map['brightness'] as num? ?? 0.0).toDouble(),
          contrast: (map['contrast'] as num? ?? 1.0).toDouble(),
          saturation: (map['saturation'] as num? ?? 1.0).toDouble(),
        ),
      );
    }
    return posts;
  }

  Future<void> deletePost(String id) async {
    final db = await database;
    await db.delete('posts', where: 'id = ?', whereArgs: [id]);
    await db.delete('likes', where: 'post_id = ?', whereArgs: [id]);
    await db.delete('comments', where: 'post_id = ?', whereArgs: [id]);
  }

  // ── Like Operations ───────────────────────────────────────────────────────

  Future<void> addLike(String postId, String userId) async {
    final db = await database;
    await db.insert('likes', {
      'post_id': postId,
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeLike(String postId, String userId) async {
    final db = await database;
    await db.delete(
      'likes',
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );
  }

  // ── Comment Operations ────────────────────────────────────────────────────

  Future<void> insertComment(String postId, Comment comment) async {
    final db = await database;
    await db.insert('comments', {
      'id': comment.id,
      'post_id': postId,
      'author_id': comment.author.id,
      'text': comment.text,
      'createdAt': comment.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await insertUser(comment.author);
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    final db = await database;
    final commentMaps = await db.query(
      'comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'createdAt ASC',
    );

    final List<Comment> comments = [];
    for (final map in commentMaps) {
      final authorId = map['author_id'] as String;
      final author = await getUser(authorId);
      if (author != null) {
        comments.add(
          Comment(
            id: map['id'] as String,
            author: author,
            text: map['text'] as String,
            createdAt: DateTime.parse(map['createdAt'] as String),
          ),
        );
      }
    }
    return comments;
  }

  // ── Story Operations ─────────────────────────────────────────────────────

  Future<void> insertStory(Story story) async {
    final db = await database;
    await db.insert('stories', {
      'id': story.id,
      'user_id': story.user.id,
      'imageUrl': story.imageUrl,
      'isVideo': story.isVideo ? 1 : 0,
      'durationSeconds': story.duration.inSeconds,
      'createdAt': story.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await insertUser(story.user);
  }

  Future<List<Story>> getAllStories() async {
    final db = await database;
    final maps = await db.query('stories', orderBy: 'createdAt DESC');

    final List<Story> stories = [];
    for (final map in maps) {
      final userId = map['user_id'] as String;
      final user = await getUser(userId);
      if (user != null) {
        stories.add(
          Story(
            id: map['id'] as String,
            user: user,
            imageUrl: map['imageUrl'] as String? ?? '',
            isVideo: (map['isVideo'] as int? ?? 0) == 1,
            duration: Duration(seconds: map['durationSeconds'] as int? ?? 5),
            createdAt: DateTime.parse(map['createdAt'] as String),
          ),
        );
      }
    }
    return stories;
  }

  Future<void> markStoryAsWatched(String storyId) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watched_stories (
        story_id TEXT PRIMARY KEY
      )
    ''');
    await db.insert('watched_stories', {
      'story_id': storyId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Set<String>> getWatchedStoryIds() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watched_stories (
        story_id TEXT PRIMARY KEY
      )
    ''');
    final maps = await db.query('watched_stories');
    return maps.map((m) => m['story_id'] as String).toSet();
  }

  // ── Follow Operations ────────────────────────────────────────────────────

  Future<void> insertFollow(String followerId, String followingId) async {
    final db = await database;
    await db.insert('follows', {
      'follower_id': followerId,
      'following_id': followingId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteFollow(String followerId, String followingId) async {
    final db = await database;
    await db.delete(
      'follows',
      where: 'follower_id = ? AND following_id = ?',
      whereArgs: [followerId, followingId],
    );
  }

  Future<Map<String, List<String>>> getAllFollows() async {
    final db = await database;
    final maps = await db.query('follows');
    final Map<String, List<String>> follows = {};

    for (final map in maps) {
      final followerId = map['follower_id'] as String;
      final followingId = map['following_id'] as String;

      if (!follows.containsKey(followerId)) {
        follows[followerId] = [];
      }
      follows[followerId]!.add(followingId);
    }
    return follows;
  }

  // ── Local Post Operations ─────────────────────────────────────────────────

  Future<void> insertLocalPost(Post post) async {
    final db = await database;
    final localMap = {
      'id': post.id,
      'author_id': post.author.id,
      'imageUrl': post.imageUrl,
      'videoUrl': post.videoUrl,
      'caption': post.caption,
      'location': post.location,
      'music': post.music,
      'musicPreviewUrl': post.musicPreviewUrl,
      'createdAt': post.createdAt.toIso8601String(),
      'isVideo': post.isVideo ? 1 : 0,
    };
    print('DB Insert Local Post: $localMap');
    await db.insert(
      'local_posts',
      localMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Post>> getLocalPosts(AppUser author) async {
    final db = await database;
    final maps = await db.query('local_posts', orderBy: 'createdAt DESC');
    print('DB Query local_posts returned ${maps.length} records: $maps');

    final List<Post> posts = [];
    for (final map in maps) {
      posts.add(
        Post(
          id: map['id'] as String,
          author: author,
          imageUrl: map['imageUrl'] as String? ?? '',
          videoUrl: map['videoUrl'] as String? ?? '',
          caption: map['caption'] as String? ?? '',
          location: map['location'] as String?,
          music: map['music'] as String?,
          musicPreviewUrl: map['musicPreviewUrl'] as String?,
          createdAt: DateTime.parse(map['createdAt'] as String),
          likedBy: [],
          comments: [],
          isVideo: (map['isVideo'] as int? ?? 0) == 1,
        ),
      );
    }
    return posts;
  }

  Future<void> deleteLocalPost(String id) async {
    final db = await database;
    await db.delete('local_posts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveAllLocalPosts(List<Post> posts) async {
    final db = await database;
    await db.delete('local_posts');
    for (final post in posts) {
      await insertLocalPost(post);
    }
  }
}
