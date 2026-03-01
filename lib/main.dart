import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: FirebaseAppConfig.options);
  }
  runApp(const EggQuestApp());
}

enum ScreenType { splash, auth, mainMenu, levelMap, game, shop, profile }

enum LevelRank { easy, hard }

LevelRank getLevelRank(int levelId) => levelId <= 15 ? LevelRank.easy : LevelRank.hard;

int getDragonTier(int levelId) {
  if (levelId <= 10) return 1;
  if (levelId <= 20) return 2;
  return 3;
}

class UserData {
  final String uid;
  final String email;
  final String displayName;
  final String avatarColor;
  final int currentLevel;
  final int unlockedLevels;
  final int totalEggs;
  final List<String> unlockedCharacters;
  final String selectedCharacterId;

  const UserData({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.avatarColor,
    required this.currentLevel,
    required this.unlockedLevels,
    required this.totalEggs,
    required this.unlockedCharacters,
    required this.selectedCharacterId,
  });

  UserData copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarColor,
    int? currentLevel,
    int? unlockedLevels,
    int? totalEggs,
    List<String>? unlockedCharacters,
    String? selectedCharacterId,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      totalEggs: totalEggs ?? this.totalEggs,
      unlockedCharacters: unlockedCharacters ?? this.unlockedCharacters,
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'avatarColor': avatarColor,
        'currentLevel': currentLevel,
        'unlockedLevels': unlockedLevels,
        'totalEggs': totalEggs,
        'unlockedCharacters': unlockedCharacters,
        'selectedCharacterId': selectedCharacterId,
      };

  static UserData fromJson(Map<String, dynamic> json) => UserData(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        avatarColor: json['avatarColor'] as String,
        currentLevel: json['currentLevel'] as int,
        unlockedLevels: json['unlockedLevels'] as int,
        totalEggs: json['totalEggs'] as int,
        unlockedCharacters: (json['unlockedCharacters'] as List<dynamic>).cast<String>(),
        selectedCharacterId: json['selectedCharacterId'] as String,
      );
}

class Character {
  final String id;
  final String name;
  final Color color;
  final int price;
  final String iconName;

  const Character({
    required this.id,
    required this.name,
    required this.color,
    required this.price,
    required this.iconName,
  });
}

class LevelConfig {
  final int id;
  final Color bgColor;
  final Color pipeColor;
  final double speed;
  final double gapSize;
  final int pipesToPass;
  final double eggProbability;

  const LevelConfig({
    required this.id,
    required this.bgColor,
    required this.pipeColor,
    required this.speed,
    required this.gapSize,
    required this.pipesToPass,
    required this.eggProbability,
  });
}

class PipeData {
  double x;
  final double topHeight;
  bool passed;
  final bool hasEgg;
  final double eggY;
  bool eggCollected;

  PipeData({
    required this.x,
    required this.topHeight,
    required this.passed,
    required this.hasEgg,
    required this.eggY,
    required this.eggCollected,
  });
}

const totalLevels = 30;

const avatarColors = [
  Color(0xFFFBBF24),
  Color(0xFFF87171),
  Color(0xFF60A5FA),
  Color(0xFF34D399),
  Color(0xFFA78BFA),
  Color(0xFFF472B6),
  Color(0xFFFB923C),
  Color(0xFF94A3B8),
];

const characters = [
  Character(id: 'bird_1', name: 'Original', color: Color(0xFFFBBF24), price: 0, iconName: 'Bird'),
  Character(id: 'bird_2', name: 'Bluey', color: Color(0xFF60A5FA), price: 50, iconName: 'Bird'),
  Character(id: 'bird_3', name: 'Rosie', color: Color(0xFFF472B6), price: 150, iconName: 'Bird'),
  Character(id: 'bird_4', name: 'Emerald', color: Color(0xFF34D399), price: 300, iconName: 'Bird'),
  Character(id: 'bird_5', name: 'Shadow', color: Color(0xFF4B5563), price: 500, iconName: 'Bird'),
];

List<LevelConfig> generateLevels() {
  const bgColors = [
    Color(0xFF0EA5E9),
    Color(0xFF38BDF8),
    Color(0xFF0284C7),
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    Color(0xFFD97706),
    Color(0xFF10B981),
    Color(0xFF34D399),
    Color(0xFF059669),
    Color(0xFF8B5CF6),
    Color(0xFFA78BFA),
    Color(0xFF7C3AED),
  ];

  const pipeColors = [
    Color(0xFF166534),
    Color(0xFF15803D),
    Color(0xFF14532D),
    Color(0xFF9A3412),
    Color(0xFFC2410C),
    Color(0xFF7C2D12),
    Color(0xFF1E3A8A),
    Color(0xFF1E40AF),
    Color(0xFF172554),
  ];

  return List.generate(totalLevels, (index) {
    final levelNum = index + 1;
    return LevelConfig(
      id: levelNum,
      bgColor: bgColors[index % bgColors.length],
      pipeColor: pipeColors[index % pipeColors.length],
      speed: 3 + (levelNum * 0.15),
      gapSize: max(160, 260 - (levelNum * 3.5)).toDouble(),
      pipesToPass: 5 + (levelNum ~/ 2),
      eggProbability: 0.3 + (levelNum * 0.01),
    );
  });
}

Color _hexToColor(String hex) {
  final value = hex.replaceAll('#', '');
  return Color(int.parse('FF$value', radix: 16));
}

String _colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2)}';

class FirebaseAppConfig {
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: 'AIzaSyAErD7oG3owrkSuGcjWMP9_HnZi9FcYZBs',
    appId: '1:1018540097624:android:810ab649a493f70bf24a2d',
    messagingSenderId: '1018540097624',
    projectId: 'b-fh-bbc87',
    databaseURL: 'https://b-fh-bbc87-default-rtdb.firebaseio.com',
    storageBucket: 'b-fh-bbc87.appspot.com',
  );
}

class FirebaseAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> onStateChanged() => _auth.authStateChanges();

  Future<User> loginOrRegister(String email, String pass) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final result = await _auth.signInWithEmailAndPassword(email: cleanEmail, password: pass);
      final user = result.user;
      if (user == null) throw Exception('Authentication failed.');
      return user;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found' || error.code == 'invalid-credential' || error.code == 'user-disabled') {
        final result = await _auth.createUserWithEmailAndPassword(email: cleanEmail, password: pass);
        final user = result.user;
        if (user == null) throw Exception('Registration failed.');
        return user;
      }
      rethrow;
    }
  }

  Future<void> logout() => _auth.signOut();
}

class FirestoreUserService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<UserData?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserData.fromJson(doc.data()!);
  }

  Future<UserData> initUserData(String uid, String email) async {
    final data = UserData(
      uid: uid,
      email: email,
      displayName: 'Egg Pilot',
      avatarColor: '#fbbf24',
      currentLevel: 1,
      unlockedLevels: 1,
      totalEggs: 0,
      unlockedCharacters: const ['bird_1'],
      selectedCharacterId: 'bird_1',
    );
    await _db.collection('users').doc(uid).set(data.toJson());
    return data;
  }

  Future<void> saveUserData(String uid, Map<String, dynamic> updates) {
    return _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));
  }
}

class EggQuestApp extends StatelessWidget {
  const EggQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Egg Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'sans-serif'),
      home: const EggQuestHome(),
    );
  }
}

class EggQuestHome extends StatefulWidget {
  const EggQuestHome({super.key});

  @override
  State<EggQuestHome> createState() => _EggQuestHomeState();
}

class _EggQuestHomeState extends State<EggQuestHome> {
  final authService = FirebaseAuthService();
  final firestoreService = FirestoreUserService();
  final levels = generateLevels();
  StreamSubscription<User?>? _authSub;

  ScreenType screen = ScreenType.splash;
  UserData? user;
  String email = '';
  String password = '';
  bool isAuthChecking = true;
  bool isLoading = false;
  bool isSyncing = false;
  String? authError;
  String? initializationError;

  String aiTip = '';
  bool isAiLoading = false;

  String tempName = '';
  Color tempColor = avatarColors.first;
  bool isSavingProfile = false;
  bool isLoginMode = true;
  String debugStatus = 'Booting...';

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  void _setDebugStatus(String message) {
    if (!kDebugMode) return;
    debugPrint('[EggQuestDebug] $message');
    if (!mounted) return;
    setState(() => debugStatus = message);
  }

  Future<void> _boot() async {
    _setDebugStatus('Initializing Firebase...');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseAppConfig.options);
      }
      _setDebugStatus('Firebase initialized. Listening auth state...');
      _authSub = authService.onStateChanged().listen((fbUser) async {
        if (!mounted) return;
        if (fbUser == null) {
          _setDebugStatus('No user session. Showing auth screen.');
          setState(() {
            user = null;
            screen = ScreenType.auth;
            isAuthChecking = false;
          });
          return;
        }
        try {
          _setDebugStatus('User detected. Syncing Firestore profile...');
          var userData = await firestoreService.getUserData(fbUser.uid);
          userData ??= await firestoreService.initUserData(fbUser.uid, fbUser.email ?? '');
          if (!mounted) return;
          setState(() {
            user = userData;
            screen = ScreenType.levelMap;
            isAuthChecking = false;
          });
          _setDebugStatus('Profile synced. Navigated to level map.');
          _setDebugStatus('Level complete. Back to map.');
      unawaited(_fetchAiTip());
        } catch (e) {
          if (!mounted) return;
          _setDebugStatus('Firestore sync failed: $e');
          setState(() {
            initializationError = 'Sync Failed: $e';
            isAuthChecking = false;
            screen = ScreenType.auth;
          });
        }
      });
    } catch (e) {
      _setDebugStatus('Boot failed: $e');
      setState(() {
        initializationError = 'Sync Failed: $e';
        isAuthChecking = false;
        screen = ScreenType.auth;
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchAiTip() async {
    if (user == null || screen != ScreenType.levelMap || aiTip.isNotEmpty || isAiLoading) return;
    setState(() => isAiLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setState(() {
      aiTip = 'Gravity is just a suggestion. Keep flapping, Pilot!';
      isAiLoading = false;
    });
  }

  Future<void> _syncSignedInUser() async {
    _setDebugStatus('Auth success. Loading user profile...');
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    var userData = await firestoreService.getUserData(fbUser.uid);
    userData ??= await firestoreService.initUserData(fbUser.uid, fbUser.email ?? '');

    if (!mounted) return;
    setState(() {
      user = userData;
      screen = ScreenType.levelMap;
      isAuthChecking = false;
      isLoading = false;
    });
    _setDebugStatus('Login complete. Welcome to level map!');
    unawaited(_fetchAiTip());
  }

  Future<void> _handleLogin() async {
    if (isLoading) return;
    _setDebugStatus('Attempting login...');
    setState(() {
      isLoading = true;
      authError = null;
    });
    try {
      final cleanEmail = email.trim().toLowerCase();
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: cleanEmail, password: password);
      await _syncSignedInUser();
    } on FirebaseAuthException catch (e) {
      _setDebugStatus('Signup failed: ${e.code}');
      setState(() {
        authError = e.message ?? e.code;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        authError = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (isLoading) return;
    _setDebugStatus('Creating account...');
    setState(() {
      isLoading = true;
      authError = null;
    });
    try {
      final cleanEmail = email.trim().toLowerCase();
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: cleanEmail, password: password);
      await _syncSignedInUser();
    } on FirebaseAuthException catch (e) {
      _setDebugStatus('Signup failed: ${e.code}');
      setState(() {
        authError = e.message ?? e.code;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        authError = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> updates) async {
    final u = user;
    if (u == null) return;

    setState(() {
      isSyncing = true;
      user = UserData.fromJson({...u.toJson(), ...updates});
    });

    try {
      await firestoreService.saveUserData(u.uid, updates);
    } finally {
      if (mounted) {
        setState(() => isSyncing = false);
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    if (user == null) return;
    setState(() => isSavingProfile = true);
    await _updateUserData({'displayName': tempName, 'avatarColor': _colorToHex(tempColor)});
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        isSavingProfile = false;
        screen = ScreenType.levelMap;
      });
    }
  }

  Future<void> _onLevelWin(int eggsCollected) async {
    final u = user;
    if (u == null) return;

    setState(() => isSyncing = true);
    final nextLvlNum = u.unlockedLevels + 1;
    final unlockedLevels = max(u.unlockedLevels, nextLvlNum);
    final updates = {
      'totalEggs': u.totalEggs + eggsCollected,
      'unlockedLevels': unlockedLevels,
      'currentLevel': nextLvlNum > totalLevels ? totalLevels : nextLvlNum,
    };

    setState(() => user = UserData.fromJson({...u.toJson(), ...updates}));
    await firestoreService.saveUserData(u.uid, updates);
    if (!mounted) return;

    setState(() {
      isSyncing = false;
      aiTip = '';
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => screen = ScreenType.levelMap);
      _setDebugStatus('Level complete. Back to map.');
      unawaited(_fetchAiTip());
    }
  }

  Future<void> _logout() async {
    _setDebugStatus('Logging out...');
    await authService.logout();
    if (!mounted) return;
    setState(() {
      user = null;
      screen = ScreenType.auth;
      email = '';
      password = '';
      aiTip = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isAuthChecking) {
      return Scaffold(
        backgroundColor: const Color(0xFF0EA5E9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(radius: 52, backgroundColor: Color(0xFFFACC15), child: Icon(Icons.flutter_dash, size: 52, color: Colors.brown)),
                const SizedBox(height: 20),
                const Text('EGG\nQUEST', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 0.95)),
                const SizedBox(height: 20),
                if (initializationError != null)
                  Column(
                    children: [
                      Text(initializationError!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      FilledButton(onPressed: _boot, child: const Text('RETRY')),
                    ],
                  )
                else
                  Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 10),
                      Text('Connecting to Cloud', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(debugStatus, style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (screen == ScreenType.auth) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isLoginMode ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                      onChanged: (v) => email = v,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      onChanged: (v) => password = v,
                    ),
                    const SizedBox(height: 10),
                    if (authError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text(authError!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : (isLoginMode ? _handleLogin : _handleSignup),
                        child: Text(isLoading ? 'LOADING...' : (isLoginMode ? 'LOGIN' : 'SIGN UP')),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(debugStatus, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => setState(() {
                                authError = null;
                                isLoginMode = !isLoginMode;
                              }),
                      child: Text(isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final currentUser = user;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Preparing account...'),
              const SizedBox(height: 6),
              Text(debugStatus, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => screen = ScreenType.auth),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (screen == ScreenType.profile) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: () => setState(() => screen = ScreenType.levelMap), icon: const Icon(Icons.chevron_left)),
          title: const Text('Profile'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: CircleAvatar(radius: 48, backgroundColor: tempColor, child: const Icon(Icons.flutter_dash, color: Colors.white, size: 38))),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: tempName),
              maxLength: 15,
              onChanged: (v) => tempName = v,
              decoration: const InputDecoration(labelText: 'Pilot Name'),
            ),
            const SizedBox(height: 14),
            const Text('Signature Color', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: avatarColors
                  .map(
                    (c) => GestureDetector(
                      onTap: () => setState(() => tempColor = c),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c == tempColor ? Colors.blue : Colors.transparent, width: 3),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isSavingProfile ? null : _handleSaveProfile,
              icon: Icon(isSavingProfile ? Icons.check_circle : Icons.save),
              label: Text(isSavingProfile ? 'SAVED!' : 'SAVE CHANGES'),
            ),
          ],
        ),
      );
    }

    if (screen == ScreenType.shop) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: () => setState(() => screen = ScreenType.levelMap), icon: const Icon(Icons.chevron_left)),
          title: const Text('Shop'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(label: Text('🥚 ${currentUser.totalEggs}')),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final char = characters[index];
            final isUnlocked = currentUser.unlockedCharacters.contains(char.id);
            final isSelected = currentUser.selectedCharacterId == char.id;
            final canAfford = currentUser.totalEggs >= char.price;

            return Card(
              color: isSelected ? const Color(0xFFE0F2FE) : null,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: char.color, child: const Icon(Icons.flutter_dash, color: Colors.white)),
                title: Text(char.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: isUnlocked
                    ? FilledButton(
                        onPressed: isSelected ? null : () => _updateUserData({'selectedCharacterId': char.id}),
                        child: Text(isSelected ? 'ACTIVE' : 'SELECT'),
                      )
                    : FilledButton(
                        onPressed: canAfford
                            ? () => _updateUserData({
                                  'totalEggs': currentUser.totalEggs - char.price,
                                  'unlockedCharacters': [...currentUser.unlockedCharacters, char.id],
                                })
                            : null,
                        child: Text('🥚 ${char.price}'),
                      ),
              ),
            );
          },
        ),
      );
    }

    if (screen == ScreenType.game) {
      final currentLevel = levels.firstWhere((l) => l.id == currentUser.currentLevel, orElse: () => levels.first);
      final currentCharacter = characters.firstWhere((c) => c.id == currentUser.selectedCharacterId, orElse: () => characters.first);
      return Scaffold(
        body: EggGameView(
          level: currentLevel,
          character: currentCharacter,
          onLose: () {},
          onExit: () => setState(() => screen = ScreenType.levelMap),
          onWin: _onLevelWin,
        ),
      );
    }

    // LEVEL MAP
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          tempName = currentUser.displayName;
                          tempColor = _hexToColor(currentUser.avatarColor);
                          screen = ScreenType.profile;
                        });
                      },
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: _hexToColor(currentUser.avatarColor), child: const Icon(Icons.flutter_dash, color: Colors.white)),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(currentUser.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Row(children: [
                              Text('Level ${currentUser.unlockedLevels}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(width: 6),
                              Icon(isSyncing ? Icons.sync : Icons.cloud_done, size: 13, color: isSyncing ? Colors.blue : Colors.green),
                            ]),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  Chip(label: Text('🥚 ${currentUser.totalEggs}')),
                ],
              ),
            ),
            if (aiTip.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.lightBlue),
                    const SizedBox(width: 8),
                    Expanded(child: Text('"$aiTip"', style: const TextStyle(fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.only(top: 12, bottom: 100),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final isUnlocked = level.id <= currentUser.unlockedLevels;
                  final isCurrent = level.id == currentUser.unlockedLevels;
                  final isHard = getLevelRank(level.id) == LevelRank.hard;
                  final offset = sin(index * 0.8) * 60;

                  return Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(offset, 0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: ElevatedButton(
                                  onPressed: !isUnlocked
                                      ? null
                                      : () {
                                          _updateUserData({'currentLevel': level.id});
                                          setState(() => screen = ScreenType.game);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    backgroundColor: isCurrent
                                        ? const Color(0xFF0EA5E9)
                                        : isUnlocked
                                            ? (isHard ? const Color(0xFFB45309) : const Color(0xFF10B981))
                                            : Colors.grey,
                                  ),
                                  child: Text(isUnlocked ? '${level.id}' : '🔒', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (isHard && isUnlocked)
                                const Positioned.fill(child: IgnorePointer(child: _HardLevelFireAura())),
                              if (isHard)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(999)),
                                    child: const Text('HARD', style: TextStyle(fontSize: 10, color: Color(0xFF9A3412), fontWeight: FontWeight.w900)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavTab(label: 'Map', icon: Icons.map, active: true, onTap: () {}),
                  _NavTab(label: 'Shop', icon: Icons.shopping_bag, active: false, onTap: () => setState(() => screen = ScreenType.shop)),
                  _NavTab(label: 'Exit', icon: Icons.logout, active: false, onTap: _logout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardLevelFireAura extends StatefulWidget {
  const _HardLevelFireAura();

  @override
  State<_HardLevelFireAura> createState() => _HardLevelFireAuraState();
}

class _HardLevelFireAuraState extends State<_HardLevelFireAura> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = 0.25 + (_controller.value * 0.45);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF6A00).withOpacity(glow), blurRadius: 18, spreadRadius: 1),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('🔥', style: TextStyle(fontSize: 14 + (_controller.value * 4))),
            ),
          ),
        );
      },
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavTab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.lightBlue : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class EggGameView extends StatefulWidget {
  final LevelConfig level;
  final Character character;
  final ValueChanged<int> onWin;
  final VoidCallback onLose;
  final VoidCallback onExit;

  const EggGameView({
    super.key,
    required this.level,
    required this.character,
    required this.onWin,
    required this.onLose,
    required this.onExit,
  });

  @override
  State<EggGameView> createState() => _EggGameViewState();
}

class _EggGameViewState extends State<EggGameView> {
  final random = Random();
  final birdY = ValueNotifier<double>(250);
  final birdVelocity = ValueNotifier<double>(0);

  final List<PipeData> pipes = [];
  final List<_Star> stars = [];

  static const gravity = 0.55;
  static const jumpForce = -8.5;
  static const terminalVelocity = 10.0;
  static const pipeWidth = 70.0;
  static const birdSize = 36.0;
  static const canvasWidth = 400.0;
  static const canvasHeight = 600.0;

  String gameState = 'IDLE';
  int score = 0;
  int eggsDisplay = 0;
  bool isShaking = false;
  Timer? _timer;
  Timer? _countdownTimer;
  int countdownValue = 3;
  String? celebrationText;
  double celebrationOpacity = 0;
  double effectClock = 0;

  @override
  void initState() {
    super.initState();
    stars.addAll(List.generate(30, (_) => _Star(random.nextDouble() * canvasWidth, random.nextDouble() * canvasHeight, random.nextDouble() * 2 + 1, random.nextDouble() * 0.5 + 0.2)));
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    birdY.dispose();
    birdVelocity.dispose();
    super.dispose();
  }

  void _initGame() {
    birdY.value = 250;
    birdVelocity.value = 0;
    score = 0;
    eggsDisplay = 0;
    gameState = 'IDLE';
    isShaking = false;
    countdownValue = 3;
    celebrationText = null;
    celebrationOpacity = 0;
    effectClock = 0;
    pipes.clear();

    final startX = canvasWidth + 100;
    const spacing = 220.0;
    for (var i = 0; i < widget.level.pipesToPass; i++) {
      pipes.add(_spawnPipe(startX + (i * spacing)));
    }

    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {});
  }

  PipeData _spawnPipe(double x) {
    final minHeight = 80.0;
    final maxHeight = canvasHeight - widget.level.gapSize - minHeight - 50;
    final topHeight = random.nextDouble() * (maxHeight - minHeight) + minHeight;
    return PipeData(
      x: x,
      topHeight: topHeight,
      passed: false,
      hasEgg: random.nextDouble() < widget.level.eggProbability,
      eggY: topHeight + (widget.level.gapSize / 2),
      eggCollected: false,
    );
  }

  Color _shade(Color c, double factor) {
    return Color.fromARGB(
      c.alpha,
      (c.red * factor).clamp(0, 255).toInt(),
      (c.green * factor).clamp(0, 255).toInt(),
      (c.blue * factor).clamp(0, 255).toInt(),
    );
  }

  void _startCountdown() {
    if (gameState == 'COUNTDOWN' || gameState == 'PLAYING') return;
    _countdownTimer?.cancel();
    setState(() {
      gameState = 'COUNTDOWN';
      countdownValue = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (countdownValue <= 1) {
        timer.cancel();
        setState(() {
          gameState = 'PLAYING';
          birdVelocity.value = jumpForce;
        });
        _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
      } else {
        setState(() => countdownValue -= 1);
      }
    });
  }

  Future<void> _showCelebration(String text) async {
    if (!mounted) return;
    setState(() {
      celebrationText = text;
      celebrationOpacity = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => celebrationOpacity = 0);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => celebrationText = null);
  }

  void _jump() {
    if (gameState == 'IDLE') {
      _startCountdown();
      return;
    }

    if (gameState == 'COUNTDOWN') {
      return;
    }

    if (gameState == 'PLAYING') {
      birdVelocity.value = jumpForce;
    }
  }

  void _triggerGameOver() {
    if (gameState == 'GAMEOVER') return;
    _timer?.cancel();
    _countdownTimer?.cancel();
    widget.onLose();
    setState(() {
      gameState = 'GAMEOVER';
      isShaking = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => isShaking = false);
    });
  }

  void _update() {
    if (!mounted || gameState != 'PLAYING') return;

    effectClock += 0.08;

    for (final star in stars) {
      star.x -= star.speed;
      if (star.x < 0) star.x = canvasWidth;
    }

    birdVelocity.value = min(terminalVelocity, birdVelocity.value + gravity);
    birdY.value += birdVelocity.value;

    if (birdY.value > canvasHeight - birdSize - 20) {
      _triggerGameOver();
      return;
    }

    if (birdY.value < 0) {
      birdY.value = 0;
      birdVelocity.value = 0;
    }

    for (final pipe in pipes) {
      pipe.x -= widget.level.speed;

      final left = 104;
      final right = 132;
      final top = birdY.value + 4;
      final bottom = birdY.value + birdSize - 4;

      if (right > pipe.x && left < pipe.x + pipeWidth) {
        if (top < pipe.topHeight || bottom > pipe.topHeight + widget.level.gapSize) {
          _triggerGameOver();
          return;
        }
      }

      if (pipe.hasEgg && !pipe.eggCollected) {
        final eggX = pipe.x + pipeWidth / 2;
        final dist = sqrt(pow(eggX - (100 + birdSize / 2), 2) + pow(pipe.eggY - (birdY.value + birdSize / 2), 2));
        if (dist < 30) {
          pipe.eggCollected = true;
          eggsDisplay++;
        }
      }

      if (!pipe.passed && pipe.x + pipeWidth < 100) {
        pipe.passed = true;
        score += 1;
        final remaining = widget.level.pipesToPass - score;
        if (remaining == 0) {
          unawaited(_showCelebration('Finish Line!'));
        } else if (remaining <= 2) {
          unawaited(_showCelebration('Almost there!'));
        } else if (score % 3 == 0) {
          unawaited(_showCelebration('Great rhythm!'));
        }

        if (score >= widget.level.pipesToPass) {
          _timer?.cancel();
          setState(() => gameState = 'WIN');
          Future<void>.delayed(const Duration(milliseconds: 900), () => widget.onWin(eggsDisplay));
          return;
        }
      }
    }

    if (pipes.isNotEmpty && pipes.first.x < -pipeWidth - 30) {
      pipes.removeAt(0);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _jump,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _shade(widget.level.bgColor, 1.15),
                  _shade(widget.level.bgColor, 0.85),
                ],
              ),
            ),
          ),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              transform: Matrix4.translationValues(isShaking ? (random.nextBool() ? 4 : -4).toDouble() : 0, 0, 0),
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: CustomPaint(
                  painter: _GamePainter(
                    stars: stars,
                    pipes: pipes,
                    birdY: birdY.value,
                    birdVelocity: birdVelocity.value,
                    birdColor: widget.character.color,
                    pipeColor: widget.level.pipeColor,
                    gapSize: widget.level.gapSize,
                    levelRank: getLevelRank(widget.level.id),
                    dragonTier: getDragonTier(widget.level.id),
                    effectClock: effectClock,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HudBox(title: 'Progress', value: '$score/${widget.level.pipesToPass}'),
                _HudBox(title: 'Eggs', value: '🥚 $eggsDisplay'),
              ],
            ),
          ),
          if (gameState == 'IDLE')
            _CenterOverlay(
              title: 'Level ${widget.level.id}',
              subtitle: 'Dragon Rank ${getDragonTier(widget.level.id)} • Pass ${widget.level.pipesToPass} pipes • Hard levels breathe fire!',
              icon: Icons.rocket_launch,
              tint: Colors.black45,
            ),
          if (gameState == 'COUNTDOWN') _CountdownOverlay(count: countdownValue),
          if (celebrationText != null)
            Positioned(
              top: 92,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: celebrationOpacity,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      celebrationText!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          if (gameState == 'GAMEOVER')
            _CrashOverlay(onRetry: _initGame, onQuit: widget.onExit, score: score, target: widget.level.pipesToPass),
          if (gameState == 'WIN')
            _WinOverlay(eggs: eggsDisplay),
        ],
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final List<_Star> stars;
  final List<PipeData> pipes;
  final double birdY;
  final double birdVelocity;
  final Color birdColor;
  final Color pipeColor;
  final double gapSize;
  final LevelRank levelRank;
  final int dragonTier;
  final double effectClock;

  _GamePainter({
    required this.stars,
    required this.pipes,
    required this.birdY,
    required this.birdVelocity,
    required this.birdColor,
    required this.pipeColor,
    required this.gapSize,
    required this.levelRank,
    required this.dragonTier,
    required this.effectClock,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white54;
    for (final s in stars) {
      canvas.drawCircle(Offset(s.x, s.y), s.size, starPaint);
    }

    final pipePaint = Paint()..color = pipeColor;
    for (final pipe in pipes) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x, 0, 70, pipe.topHeight), const Radius.circular(8)),
        pipePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x, pipe.topHeight + gapSize, 70, 1000), const Radius.circular(8)),
        pipePaint,
      );
      if (pipe.hasEgg && !pipe.eggCollected) {
        final eggPaint = Paint()..color = const Color(0xFFFACC15);
        canvas.drawOval(Rect.fromCenter(center: Offset(pipe.x + 35, pipe.eggY), width: 16, height: 20), eggPaint);
      }
    }

    canvas.save();
    canvas.translate(118, birdY + 18);
    canvas.rotate((birdVelocity * 0.04).clamp(-0.35, 0.45));

    final bodyPaint = Paint()..color = birdColor;
    final wingPaint = Paint()..color = Color.lerp(birdColor, Colors.black, 0.25)!;
    final accentPaint = Paint()..color = dragonTier >= 3 ? const Color(0xFFDC2626) : const Color(0xFFF97316);

    final bodyRadius = dragonTier == 1 ? 16.0 : dragonTier == 2 ? 18.0 : 20.0;
    canvas.drawCircle(Offset.zero, bodyRadius, bodyPaint);

    final wingFlap = sin(effectClock * 2.3) * 4;
    final leftWing = Path()
      ..moveTo(-2, -2)
      ..lineTo(-24, -8 - wingFlap)
      ..lineTo(-10, 8)
      ..close();
    final rightWing = Path()
      ..moveTo(2, -2)
      ..lineTo(-10, 8)
      ..lineTo(-24, 16 + wingFlap)
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    canvas.drawPath(rightWing, wingPaint);

    final horn = Path()
      ..moveTo(4, -12)
      ..lineTo(9, -24)
      ..lineTo(14, -12)
      ..close();
    canvas.drawPath(horn, accentPaint);

    canvas.drawCircle(const Offset(7, -5), 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(8, -5), 1.5, Paint()..color = Colors.black);

    final mouth = Path()
      ..moveTo(12, 1)
      ..lineTo(26, 4)
      ..lineTo(12, 8)
      ..close();
    canvas.drawPath(mouth, accentPaint);

    if (levelRank == LevelRank.hard) {
      final fireLen = 16 + (sin(effectClock * 4.5).abs() * 12);
      final fire = Path()
        ..moveTo(24, 4)
        ..lineTo(24 + fireLen, -1)
        ..lineTo(24 + fireLen, 9)
        ..close();
      canvas.drawPath(fire, Paint()..color = const Color(0xFFFF6A00).withOpacity(0.8));
      canvas.drawCircle(Offset(24 + fireLen + 4, 4), 3, Paint()..color = const Color(0xFFFFC107).withOpacity(0.75));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}

class _HudBox extends StatelessWidget {
  final String title;
  final String value;

  const _HudBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CenterOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  const _CenterOverlay({required this.title, required this.subtitle, required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tint,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 90, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int count;

  const _CountdownOverlay({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x66000000),
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 260),
          scale: 1.0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrashOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onQuit;
  final int score;
  final int target;

  const _CrashOverlay({required this.onRetry, required this.onQuit, required this.score, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC450A0A),
      child: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.white, size: 80),
              const SizedBox(height: 8),
              const Text('CRASHED!', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('$score / $target', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: onRetry, child: const Text('RETRY'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onQuit, child: const Text('QUIT', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinOverlay extends StatelessWidget {
  final int eggs;

  const _WinOverlay({required this.eggs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC22C55E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flutter_dash, color: Colors.white, size: 100),
            const SizedBox(height: 8),
            const Text('CLEARED!', style: TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('+$eggs 🥚', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _Star {
  double x;
  double y;
  double size;
  double speed;

  _Star(this.x, this.y, this.size, this.speed);
}
