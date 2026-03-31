import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: FirebaseAppConfig.options);
  }
  runApp(const EggQuestApp());
}

enum ScreenType { splash, auth, mainMenu, levelMap, game, shop, profile }

// ─── Difficulty rank ───────────────────────────────────────────────────────
enum LevelRank { easy, medium, hard, boss }

bool isHardLevel(LevelRank rank) => rank == LevelRank.boss;

String rankLabel(LevelRank rank) {
  switch (rank) {
    case LevelRank.easy:   return 'EASY';
    case LevelRank.medium: return 'MEDIUM';
    case LevelRank.hard:   return 'HARD';
    case LevelRank.boss:   return 'BOSS';
  }
}

Color rankColor(LevelRank rank) {
  switch (rank) {
    case LevelRank.easy:   return const Color(0xFF22C55E);
    case LevelRank.medium: return const Color(0xFFF59E0B);
    case LevelRank.hard:   return const Color(0xFFEF4444);
    case LevelRank.boss:   return const Color(0xFF7C3AED);
  }
}

// ─── Chapter definition ────────────────────────────────────────────────────
class ChapterDef {
  final int number;
  final String name;
  final String emoji;
  final Color color;
  final Color bgColor;
  final Color pipeColor;
  final List<LevelRank> levelRanks;

  const ChapterDef({
    required this.number,
    required this.name,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.pipeColor,
    required this.levelRanks,
  });
}

// ─── 5 hand-crafted chapters, 6 levels each = 30 total ────────────────────
// Difficulties are intentionally mixed — not a ramp — so players feel
// rhythm changes. Every chapter's final level is always BOSS (fire level).
const List<ChapterDef> chapters = [
  // ── Chapter 1 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 1,
    name: 'Sunny Skies',
    emoji: '☀️',
    color: Color(0xFF0EA5E9),
    bgColor: Color(0xFF38BDF8),
    pipeColor: Color(0xFF166534),
    levelRanks: [
      LevelRank.easy, LevelRank.medium, LevelRank.easy,
      LevelRank.hard, LevelRank.medium, LevelRank.boss,
    ],
  ),
  // ── Chapter 2 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 2,
    name: 'Emerald Jungle',
    emoji: '🌿',
    color: Color(0xFF10B981),
    bgColor: Color(0xFF059669),
    pipeColor: Color(0xFF14532D),
    levelRanks: [
      LevelRank.medium, LevelRank.easy, LevelRank.hard,
      LevelRank.medium, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 3 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 3,
    name: 'Desert Storm',
    emoji: '🏜️',
    color: Color(0xFFF59E0B),
    bgColor: Color(0xFFD97706),
    pipeColor: Color(0xFF9A3412),
    levelRanks: [
      LevelRank.hard, LevelRank.medium, LevelRank.hard,
      LevelRank.easy, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 4 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 4,
    name: 'Mystic Caves',
    emoji: '🔮',
    color: Color(0xFF8B5CF6),
    bgColor: Color(0xFF6D28D9),
    pipeColor: Color(0xFF1E3A8A),
    levelRanks: [
      LevelRank.medium, LevelRank.hard, LevelRank.hard,
      LevelRank.easy, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 5 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 5,
    name: 'Inferno Peak',
    emoji: '🌋',
    color: Color(0xFFEF4444),
    bgColor: Color(0xFFB91C1C),
    pipeColor: Color(0xFF7C2D12),
    levelRanks: [
      LevelRank.hard, LevelRank.hard, LevelRank.medium,
      LevelRank.hard, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 6 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 6,
    name: 'Frozen Tundra',
    emoji: '❄️',
    color: Color(0xFF67E8F9),
    bgColor: Color(0xFF0E7490),
    pipeColor: Color(0xFF164E63),
    levelRanks: [
      LevelRank.medium, LevelRank.hard, LevelRank.easy,
      LevelRank.hard, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 7 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 7,
    name: 'Haunted Swamp',
    emoji: '🦇',
    color: Color(0xFF4ADE80),
    bgColor: Color(0xFF166534),
    pipeColor: Color(0xFF14532D),
    levelRanks: [
      LevelRank.hard, LevelRank.easy, LevelRank.hard,
      LevelRank.hard, LevelRank.medium, LevelRank.boss,
    ],
  ),
  // ── Chapter 8 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 8,
    name: 'Thunder Peaks',
    emoji: '⚡',
    color: Color(0xFFFBBF24),
    bgColor: Color(0xFF78350F),
    pipeColor: Color(0xFF451A03),
    levelRanks: [
      LevelRank.hard, LevelRank.hard, LevelRank.easy,
      LevelRank.hard, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 9 ─────────────────────────────────────────────────────────────
  ChapterDef(
    number: 9,
    name: 'Neon City',
    emoji: '🌃',
    color: Color(0xFFE879F9),
    bgColor: Color(0xFF4C0570),
    pipeColor: Color(0xFF3B0764),
    levelRanks: [
      LevelRank.hard, LevelRank.hard, LevelRank.medium,
      LevelRank.hard, LevelRank.hard, LevelRank.boss,
    ],
  ),
  // ── Chapter 10 ────────────────────────────────────────────────────────────
  ChapterDef(
    number: 10,
    name: 'The Final Void',
    emoji: '🌌',
    color: Color(0xFFF43F5E),
    bgColor: Color(0xFF0F172A),
    pipeColor: Color(0xFF1E293B),
    levelRanks: [
      LevelRank.hard, LevelRank.hard, LevelRank.hard,
      LevelRank.hard, LevelRank.hard, LevelRank.boss,
    ],
  ),
];

// ─── Lookup helpers ────────────────────────────────────────────────────────
ChapterDef getChapter(int levelId) {
  int rem = levelId;
  for (final ch in chapters) {
    if (rem <= ch.levelRanks.length) return ch;
    rem -= ch.levelRanks.length;
  }
  return chapters.last;
}

LevelRank getLevelRank(int levelId) {
  int rem = levelId;
  for (final ch in chapters) {
    if (rem <= ch.levelRanks.length) return ch.levelRanks[rem - 1];
    rem -= ch.levelRanks.length;
  }
  return LevelRank.boss;
}

/// 1-based position of a level within its chapter.
int levelIndexInChapter(int levelId) {
  int rem = levelId;
  for (final ch in chapters) {
    if (rem <= ch.levelRanks.length) return rem;
    rem -= ch.levelRanks.length;
  }
  return 1;
}

int getDragonTier(int levelId) {
  final ch = getChapter(levelId);
  if (ch.number <= 3) return 1;
  if (ch.number <= 7) return 2;
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
  final int birdType; // 0=Crystal 1=Azure 2=Prism 3=Owl 4=Raven 5=Granite 6=Phoenix 7=Inferno

  const Character({
    required this.id,
    required this.name,
    required this.color,
    required this.price,
    required this.iconName,
    this.birdType = 0,
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
  final bool isBossLevel;        // pipes oscillate vertically
  final double pipeOscAmp;       // boss oscillation amplitude (px)
  final double pipeOscSpeed;     // boss oscillation speed (rad/tick)
  final int birdTier;            // 1 (tiny chick) → 10 (massive inferno dragon)

  const LevelConfig({
    required this.id,
    required this.bgColor,
    required this.pipeColor,
    required this.speed,
    required this.gapSize,
    required this.pipesToPass,
    required this.eggProbability,
    this.isBossLevel = false,
    this.pipeOscAmp = 0,
    this.pipeOscSpeed = 0,
    this.birdTier = 1,
  });
}

class PipeData {
  double x;
  double topHeight;        // mutable for boss vertical movement
  bool passed;
  final bool hasEgg;
  double eggY;             // mutable — follows pipe movement
  bool eggCollected;

  // Boss-level vertical oscillation
  final double baseTopHeight; // original spawn height
  double oscillationAmp;  // pixels to move up/down
  final double oscillationSpeed; // radians per tick
  double oscillationPhase;       // current phase offset (unique per pipe)

  PipeData({
    required this.x,
    required this.topHeight,
    required this.passed,
    required this.hasEgg,
    required this.eggY,
    required this.eggCollected,
    this.oscillationAmp = 0,
    this.oscillationSpeed = 0,
    this.oscillationPhase = 0,
  }) : baseTopHeight = topHeight;
}

const totalLevels = 60;

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
  Character(id: 'bird_1', name: '🐦 Sparrow',   color: Color(0xFF64B5F6), price: 0,    iconName: 'Bird', birdType: 0),
  Character(id: 'bird_2', name: '🦋 Butterfly',  color: Color(0xFFCE93D8), price: 80,   iconName: 'Bird', birdType: 1),
  Character(id: 'bird_3', name: '🦚 Peacock',    color: Color(0xFF26A69A), price: 180,  iconName: 'Bird', birdType: 2),
  Character(id: 'bird_4', name: '🦉 Owl',        color: Color(0xFF8D6E63), price: 300,  iconName: 'Bird', birdType: 3),
  Character(id: 'bird_5', name: '🐦‍⬛ Raven',     color: Color(0xFF455A64), price: 450,  iconName: 'Bird', birdType: 4),
  Character(id: 'bird_6', name: '🦅 Eagle',      color: Color(0xFF8D6E63), price: 650,  iconName: 'Bird', birdType: 5),
  Character(id: 'bird_7', name: '🦜 Parrot',     color: Color(0xFF43A047), price: 900,  iconName: 'Bird', birdType: 6),
  Character(id: 'bird_8', name: '🐲 Dragon',     color: Color(0xFFE53935), price: 1400, iconName: 'Bird', birdType: 7),
];

List<LevelConfig> generateLevels() {
  // Flat list: total 60 levels across 10 chapters of 6 levels each.
  // Difficulty climbs smoothly from level 1 → 60 using a global 't' [0..1].
  // Within each chapter the non-boss levels build up, and the boss spikes.
  // Boss levels (always position 6 in each chapter) get oscillating pipes.

  final List<LevelConfig> result = [];
  int globalId = 1;
  final int totalLevs = chapters.fold(0, (s, c) => s + c.levelRanks.length);

  for (final ch in chapters) {
    final chIdx = ch.number - 1; // 0-based

    for (int i = 0; i < ch.levelRanks.length; i++) {
      final rank = ch.levelRanks[i];
      // Global progress 0.0 (level 1) → 1.0 (last level)
      final t = (globalId - 1) / (totalLevs - 1).toDouble();

      // ── Base difficulty curves (linear with slight ease-in) ────────────
      // Speed: 2.8 (very slow) → 10.0 (very fast) smoothly
      final baseSpeed = 2.8 + t * 7.2;
      // Gap: 255px (huge) → 145px (tight) smoothly
      final baseGap   = 255.0 - t * 110.0;
      // Pipes to pass: 4 → 18
      final basePipes = (4 + t * 14).round();
      // Egg probability: 0.65 → 0.18
      final baseEgg   = 0.65 - t * 0.47;

      // ── Per-rank modifier on top of the smooth base ────────────────────
      final double speed;
      final double gapSize;
      final int pipesToPass;
      final double eggProbability;
      bool isBossLevel = false;
      double pipeOscAmp = 0;
      double pipeOscSpeed = 0;

      switch (rank) {
        case LevelRank.easy:
          // Gentler than base — gives players a breather
          speed         = (baseSpeed * 0.82).clamp(2.8, 10.0);
          gapSize       = (baseGap  * 1.15).clamp(145.0, 260.0);
          pipesToPass   = max(4, basePipes - 2);
          eggProbability = (baseEgg * 1.20).clamp(0.18, 0.72);
          break;
        case LevelRank.medium:
          speed         = (baseSpeed * 0.95).clamp(2.8, 10.0);
          gapSize       = (baseGap  * 1.05).clamp(145.0, 260.0);
          pipesToPass   = basePipes;
          eggProbability = baseEgg.clamp(0.18, 0.65);
          break;
        case LevelRank.hard:
          speed         = (baseSpeed * 1.12).clamp(2.8, 11.0);
          gapSize       = (baseGap  * 0.90).clamp(145.0, 260.0);
          pipesToPass   = min(22, basePipes + 2);
          eggProbability = (baseEgg * 0.75).clamp(0.15, 0.45);
          break;
        case LevelRank.boss:
          // Boss: fastest + tightest gap + oscillating pipes
          speed         = (baseSpeed * 1.30).clamp(3.5, 13.0);
          gapSize       = (baseGap  * 0.88).clamp(155.0, 210.0);  // slightly more room for moving pipes
          pipesToPass   = min(25, basePipes + 4);
          eggProbability = 0.18;
          isBossLevel   = true;
          // Dramatic oscillation: amp 55→120px, speed 0.045→0.085 rad/tick
          // At 62fps: 0.045 rad/tick ≈ 0.45s per full swing — very visible
          pipeOscAmp    = 75.0 + chIdx * 5.0;
          pipeOscSpeed  = 0.06 + chIdx * 0.004;
          break;
      }

      // Boss levels get dark pipe colour; others get the chapter's lighter tint
      final pipeColor = rank == LevelRank.boss
          ? ch.pipeColor
          : Color.lerp(ch.pipeColor, Colors.white, 0.20)!;

      // Bird tier 1-10: based on global progress, boss levels jump to +1 tier
      // t goes 0→1 across all 60 levels, giving tiers 1→9 for normal levels
      // Boss adds +1 on top so they always feel like a step up
      final birdTier = (1 + (t * 8.5).floor() + (isBossLevel ? 1 : 0)).clamp(1, 10);

      result.add(LevelConfig(
        id: globalId,
        bgColor: ch.bgColor,
        pipeColor: pipeColor,
        speed: speed,
        gapSize: gapSize,
        pipesToPass: pipesToPass,
        eggProbability: eggProbability,
        isBossLevel: isBossLevel,
        pipeOscAmp: pipeOscAmp,
        pipeOscSpeed: pipeOscSpeed,
        birdTier: birdTier,
      ));
      globalId++;
    }
  }
  return result;
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

// ─── Global theme notifier — starts with system default ───────────────────
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

class EggQuestApp extends StatelessWidget {
  const EggQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, mode, __) => MaterialApp(
        title: 'Egg Quest',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: const Color(0xFFFBBF24),
          fontFamily: 'sans-serif',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFFFBBF24),
          fontFamily: 'sans-serif',
        ),
        home: const EggQuestHome(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash Screen — branded intro that fades in then out
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;
  late Animation<double> _scale;
  late Animation<double> _poweredFade;

  @override
  void initState() {
    super.initState();
    // Total: 0-600ms fade in, 600-2200ms hold, 2200-2800ms fade out
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.30, curve: Curves.easeOutBack)),
    );

    _poweredFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.82, 1.0, curve: Curves.easeIn)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF060D1A) : const Color(0xFFF8F4E8);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final taglineColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final poweredLabelColor = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final glowColor = const Color(0xFFFBBF24).withOpacity(isDark ? 0.14 : 0.22);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final alpha = (_fadeIn.value * _fadeOut.value).clamp(0.0, 1.0);
        return Scaffold(
          backgroundColor: bgColor,
          body: Opacity(
            opacity: alpha,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Radial background glow
                Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [glowColor, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Main content
                Center(
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🥚', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 16),
                        Text(
                          'EGG QUEST',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fly. Dodge. Evolve.',
                          style: TextStyle(
                            color: taglineColor,
                            fontSize: 15,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 52,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _poweredFade.value,
                    child: Column(
                      children: [
                        Text(
                          'POWERED BY',
                          style: TextStyle(
                            color: poweredLabelColor,
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'LookersHub',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  bool _showSplash = true;

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
    // Keep splash visible for at least 3 s regardless of auth speed
    Future<void>.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _showSplash = false);
    });
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
    if (isAuthChecking || _showSplash) {
      return const _SplashScreen();
    }

    if (screen == ScreenType.auth) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1221),
        // resizeToAvoidBottomInset lets the scaffold push content up when keyboard appears
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            // Scroll when keyboard is visible so nothing is hidden
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo area
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                      ).createShader(bounds),
                      child: const Text(
                        '🥚',
                        style: TextStyle(fontSize: 64),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'EGG QUEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Powered by LookersHub',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 40),
                    // Auth card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isLoginMode ? 'Welcome Back' : 'Create Account',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLoginMode ? 'Sign in to continue your quest' : 'Start your egg adventure',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 1.5),
                                ),
                              ),
                              onChanged: (v) => email = v,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 1.5),
                                ),
                              ),
                              onChanged: (v) => password = v,
                            ),
                            if (authError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
                                ),
                                child: Text(
                                  authError!,
                                  style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFBBF24),
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: isLoading ? null : (isLoginMode ? _handleLogin : _handleSignup),
                                child: Text(
                                  isLoading ? 'Please wait...' : (isLoginMode ? 'LOGIN' : 'SIGN UP'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (debugStatus.isNotEmpty)
                              Text(debugStatus, style: const TextStyle(fontSize: 10, color: Color(0xFF475569)), textAlign: TextAlign.center),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => setState(() {
                                        authError = null;
                                        isLoginMode = !isLoginMode;
                                      }),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
                              child: Text(
                                isLoginMode ? "Don't have an account?  Sign up →" : "Already have an account?  Login →",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            // Theme toggle
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appThemeMode,
              builder: (ctx, mode, _) {
                final isDark = mode == ThemeMode.dark ||
                    (mode == ThemeMode.system &&
                        MediaQuery.platformBrightnessOf(ctx) == Brightness.dark);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final entry in [
                          (ThemeMode.system, Icons.brightness_auto, 'Auto'),
                          (ThemeMode.light,  Icons.light_mode,       'Light'),
                          (ThemeMode.dark,   Icons.dark_mode,        'Dark'),
                        ])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => appThemeMode.value = entry.$1,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: appThemeMode.value == entry.$1
                                      ? const Color(0xFFFBBF24)
                                      : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: appThemeMode.value == entry.$1
                                        ? const Color(0xFFF59E0B)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(entry.$2,
                                      size: 22,
                                      color: appThemeMode.value == entry.$1 ? Colors.black87 : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(entry.$3,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: appThemeMode.value == entry.$1 ? Colors.black87 : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
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
          title: const Text('Bird Shop'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(label: Text('🥚 ${currentUser.totalEggs}')),
            ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final char = characters[index];
            final isUnlocked = currentUser.unlockedCharacters.contains(char.id);
            final isSelected = currentUser.selectedCharacterId == char.id;
            final canAfford = currentUser.totalEggs >= char.price;

            return Card(
              elevation: isSelected ? 6 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isSelected
                    ? BorderSide(color: char.color, width: 3)
                    : BorderSide.none,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      char.color.withOpacity(0.12),
                      Colors.white,
                    ],
                  ),
                ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated bird preview — LayoutBuilder gives it a real size
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) => Center(
                          child: SizedBox(
                            width: constraints.maxWidth * 0.85,
                            height: constraints.maxHeight * 0.85,
                            child: _ShopBirdPreview(character: char),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      char.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: char.color.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: char.color, borderRadius: BorderRadius.circular(99)),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      )
                    else if (isUnlocked)
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: char.color, minimumSize: const Size(90, 32)),
                        onPressed: () => _updateUserData({'selectedCharacterId': char.id}),
                        child: const Text('SELECT'),
                      )
                    else
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: canAfford ? char.color : Colors.grey.shade400,
                          minimumSize: const Size(90, 32),
                        ),
                        onPressed: canAfford
                            ? () => _updateUserData({
                                  'totalEggs': currentUser.totalEggs - char.price,
                                  'unlockedCharacters': [...currentUser.unlockedCharacters, char.id],
                                })
                            : null,
                        child: Text('🥚 ${char.price}'),
                      ),
                    const SizedBox(height: 10),
                  ],
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
              child: _buildLevelMap(currentUser),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
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

  // ── Chapter-grouped level map ─────────────────────────────────────────────
  Widget _buildLevelMap(UserData currentUser) {
    return _LevelMapScroller(
      currentUser: currentUser,
      levels: levels,
      onLevelTap: (levelId) {
        _updateUserData({'currentLevel': levelId});
        setState(() => screen = ScreenType.game);
      },
    );
  }

  int _chapterStartId(ChapterDef ch) {
    int id = 1;
    for (final c in chapters) {
      if (c.number == ch.number) return id;
      id += c.levelRanks.length;
    }
    return id;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level map scroller — auto-scrolls to current level on first build
// ─────────────────────────────────────────────────────────────────────────────

class _LevelMapScroller extends StatefulWidget {
  final UserData currentUser;
  final List<LevelConfig> levels;
  final void Function(int levelId) onLevelTap;

  const _LevelMapScroller({
    required this.currentUser,
    required this.levels,
    required this.onLevelTap,
  });

  @override
  State<_LevelMapScroller> createState() => _LevelMapScrollerState();
}

class _LevelMapScrollerState extends State<_LevelMapScroller> {
  final ScrollController _scrollController = ScrollController();

  // Each item is roughly 108px tall (88 button + 9+9 padding + badge overflow).
  // Chapter banners are ~72px.
  // We build the flat reversed list first, then after layout jump to the
  // index that corresponds to the current level.
  static const double _itemHeight = 108.0;
  static const double _bannerHeight = 80.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLevel());
  }

  @override
  void didUpdateWidget(_LevelMapScroller old) {
    super.didUpdateWidget(old);
    if (old.currentUser.unlockedLevels != widget.currentUser.unlockedLevels) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLevel());
    }
  }

  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;

    final currentLevelId = widget.currentUser.unlockedLevels;

    // Build the same flat reversed list and find the index of the current level
    final List<_MapItem> items = _buildItems();
    final reversed = items.reversed.toList();

    int targetIndex = 0;
    for (int i = 0; i < reversed.length; i++) {
      final item = reversed[i];
      if (item.levelId == currentLevelId) {
        targetIndex = i;
        break;
      }
    }

    // Estimate pixel offset
    double offset = 0;
    for (int i = 0; i < targetIndex; i++) {
      offset += reversed[i].isBanner ? _bannerHeight : _itemHeight;
    }

    // Center it on screen
    final viewportHeight = _scrollController.position.viewportDimension;
    offset = (offset - viewportHeight / 2 + _itemHeight / 2).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  List<_MapItem> _buildItems() {
    final List<_MapItem> items = [];
    for (final ch in chapters) {
      final startId = _chapterStartId(ch);
      items.add(_MapItem.banner(ch));
      for (int i = 0; i < ch.levelRanks.length; i++) {
        items.add(_MapItem.level(startId + i));
      }
    }
    return items;
  }

  int _chapterStartId(ChapterDef ch) {
    int id = 1;
    for (final c in chapters) {
      if (c.number == ch.number) return id;
      id += c.levelRanks.length;
    }
    return id;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final reversed = items.reversed.toList();
    int globalIndex = 0; // sin-wave offset counter (counts only level items)

    // Pre-compute globalIndex per level item in forward order so reversed has correct wave
    final Map<int, int> levelSinIndex = {};
    for (final item in items) {
      if (!item.isBanner) {
        levelSinIndex[item.levelId!] = globalIndex++;
      }
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 110),
      itemCount: reversed.length,
      itemBuilder: (context, i) {
        final item = reversed[i];

        if (item.isBanner) {
          final ch = item.chapter!;
          final chapterStartId = _chapterStartId(ch);
          final chapterUnlocked = widget.currentUser.unlockedLevels >= chapterStartId;
          return _ChapterBanner(chapter: ch, unlocked: chapterUnlocked);
        }

        final levelId = item.levelId!;
        final level = widget.levels.firstWhere((l) => l.id == levelId);
        final isUnlocked = levelId <= widget.currentUser.unlockedLevels;
        final isCurrent = levelId == widget.currentUser.unlockedLevels;
        final ch = getChapter(levelId);
        final rank = getLevelRank(levelId);
        final isBoss = rank == LevelRank.boss;
        final sinIdx = levelSinIndex[levelId] ?? 0;
        final offset = sin(sinIdx * 0.8) * 55;

        Color btnColor;
        if (!isUnlocked) {
          btnColor = Colors.grey.shade400;
        } else if (isCurrent) {
          btnColor = ch.color;
        } else if (isBoss) {
          btnColor = const Color(0xFF7C3AED);
        } else {
          btnColor = rankColor(rank);
        }

        return Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(offset, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
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
                            : () => widget.onLevelTap(levelId),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          backgroundColor: btnColor,
                          elevation: isCurrent ? 8 : 3,
                          shadowColor: isCurrent ? ch.color.withOpacity(0.6) : null,
                        ),
                        child: Text(
                          isUnlocked ? '$levelId' : '🔒',
                          style: TextStyle(
                            fontSize: isCurrent ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (isBoss && isUnlocked)
                      const Positioned.fill(child: IgnorePointer(child: _HardLevelFireAura())),
                    if (isUnlocked)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: (rank == LevelRank.hard || rank == LevelRank.boss)
                              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
                              : const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isBoss ? const Color(0xFF7C3AED) : rankColor(rank),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: (rank == LevelRank.hard || rank == LevelRank.boss)
                              ? Text(
                                  rankLabel(rank),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    if (isCurrent)
                      Positioned(
                        bottom: -14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ch.color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('▶ HERE', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lightweight discriminated union for map list items.
class _MapItem {
  final bool isBanner;
  final ChapterDef? chapter;
  final int? levelId;

  const _MapItem.banner(ChapterDef ch) : isBanner = true, chapter = ch, levelId = null;
  const _MapItem.level(int id) : isBanner = false, chapter = null, levelId = id;
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter banner — shown between chapter groups on the level map
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterBanner extends StatelessWidget {
  final ChapterDef chapter;
  final bool unlocked;

  const _ChapterBanner({required this.chapter, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: unlocked ? chapter.color.withOpacity(0.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? chapter.color.withOpacity(0.5) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(chapter.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${chapter.number}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: unlocked ? chapter.color : Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    chapter.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: unlocked ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              const Icon(Icons.lock, color: Colors.grey, size: 20)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chapter.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${chapter.levelRanks.length} levels',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hard-level fire aura widget on the level map button
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Nav tab
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Game view
// ─────────────────────────────────────────────────────────────────────────────

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
  int _bossPipeIndex = 0; // only this index pipe oscillates in boss level
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

  // Speed boost power-up
  bool isBoosted = false;
  Timer? _boostTimer;
  static const boostEggCost = 5;
  static const boostDuration = Duration(seconds: 1);
  static const boostMultiplier = 2.5; // speed factor during boost

  // Crash visual overlay
  bool showCrashFlash = false;

  // Feather particles on crash
  final List<_Feather> feathers = [];

  // Win fly-out animation
  bool winFlyOut = false;
  double winBirdX = 118;
  double boostBirdX = 0.0; // extra forward offset during boost lunge

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
    _boostTimer?.cancel();
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
    isBoosted = false;
    showCrashFlash = false;
    winFlyOut = false;
    winBirdX = 118;
    boostBirdX = 0.0;
    _bossPipeIndex = 0;
    _boostTimer?.cancel();
    feathers.clear();
    pipes.clear();

    final startX = canvasWidth + 100;
    const spacing = 320.0;  // more breathing room between pipes
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
    // Each pipe gets a unique phase so they don't all move in sync
    final phase = random.nextDouble() * 6.28;
    // In boss levels, only the currently tracked pipe oscillates
    final isOscillating = widget.level.isBossLevel &&
        pipes.length == _bossPipeIndex;
    return PipeData(
      x: x,
      topHeight: topHeight,
      passed: false,
      hasEgg: random.nextDouble() < widget.level.eggProbability,
      eggY: topHeight + (widget.level.gapSize / 2),
      eggCollected: false,
      oscillationAmp: isOscillating ? widget.level.pipeOscAmp : 0,
      oscillationSpeed: widget.level.pipeOscSpeed,
      oscillationPhase: phase,
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
    if (gameState == 'COUNTDOWN') return;
    if (gameState == 'PLAYING') {
      birdVelocity.value = jumpForce;
    }
  }

  void _triggerGameOver() {
    if (gameState == 'GAMEOVER') return;
    _timer?.cancel();
    _countdownTimer?.cancel();
    _boostTimer?.cancel();
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
    // Spawn feather burst
    for (int i = 0; i < 14; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 3.5 + 1.5;
      feathers.add(_Feather(
        x: 118,
        y: birdY.value + 18,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 2.0,
        rotation: random.nextDouble() * 2 * pi,
        rotSpeed: (random.nextDouble() - 0.5) * 0.3,
        color: widget.character.color,
        life: 1.0,
      ));
    }
    widget.onLose();
    setState(() {
      gameState = 'GAMEOVER';
      isShaking = true;
      showCrashFlash = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => showCrashFlash = false);
    });
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => isShaking = false);
    });
  }

  void _activateBoost() {
    if (!mounted) return;
    if (eggsDisplay < boostEggCost) return;
    if (isBoosted) return;
    if (gameState != 'PLAYING') return;
    _boostTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      eggsDisplay -= boostEggCost;
      isBoosted = true;
      boostBirdX = 0.0;
    });
    // Animate the bird lunging forward over boostDuration then snapping back
    const steps = 20;
    const stepMs = 50; // 20 steps * 50ms = 1000ms total
    const maxLunge = 80.0; // pixels forward at peak
    for (int i = 0; i < steps; i++) {
      Future.delayed(Duration(milliseconds: i * stepMs), () {
        if (!mounted) return;
        // Sine curve: ramp up then ramp down
        final t = i / (steps - 1);
        final lunge = maxLunge * sin(t * pi);
        setState(() => boostBirdX = lunge);
      });
    }
    _boostTimer = Timer(boostDuration, () {
      if (mounted) setState(() { isBoosted = false; boostBirdX = 0.0; });
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
      pipe.x -= widget.level.speed * (isBoosted ? boostMultiplier : 1.0);

      // Boss-level: only one pipe oscillates at a time ─────────────────────
      if (widget.level.isBossLevel) {
        final pIdx = pipes.indexOf(pipe);
        if (pIdx == _bossPipeIndex && pipe.oscillationAmp > 0) {
          pipe.oscillationPhase += pipe.oscillationSpeed;
          final dy = sin(pipe.oscillationPhase) * pipe.oscillationAmp;
          pipe.topHeight = (pipe.baseTopHeight + dy)
              .clamp(55.0, canvasHeight - widget.level.gapSize - 55.0);
          pipe.eggY = pipe.topHeight + widget.level.gapSize / 2;
        }
      }

      final left = 104;
      final right = 132;
      final top = birdY.value + 4;
      final bottom = birdY.value + birdSize - 4;

      if (right > pipe.x && left < pipe.x + pipeWidth) {
        final hitTop    = top    < pipe.topHeight;
        final hitBottom = bottom > pipe.topHeight + widget.level.gapSize;
        if (hitTop || hitBottom) {
          _triggerGameOver();
          return;
        }
        // Near-miss graze — shed a feather if very close to a pipe edge
        final marginTop    = top    - pipe.topHeight;
        final marginBottom = (pipe.topHeight + widget.level.gapSize) - bottom;
        if ((marginTop < 14 || marginBottom < 14) && random.nextInt(4) == 0) {
          final angle = random.nextDouble() * 2 * pi;
          feathers.add(_Feather(
            x: 118,
            y: birdY.value + 18,
            vx: cos(angle) * (random.nextDouble() * 2 + 1),
            vy: sin(angle) * (random.nextDouble() * 2 + 1) - 1.5,
            rotation: random.nextDouble() * 2 * pi,
            rotSpeed: (random.nextDouble() - 0.5) * 0.25,
            color: widget.character.color,
            life: 0.9,
          ));
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
        // In boss level: move the oscillating pipe to the next one
        if (widget.level.isBossLevel && pipes.indexOf(pipe) == _bossPipeIndex) {
          pipe.oscillationAmp = 0; // stop this pipe
          setState(() => _bossPipeIndex++);
          // Give amp to next pipe if it exists
          if (_bossPipeIndex < pipes.length) {
            pipes[_bossPipeIndex].oscillationAmp = widget.level.pipeOscAmp;
          }
        }
        score += 1;
        final remaining = widget.level.pipesToPass - score;
        // Exciting milestone messages
        if (remaining == 0) {
          unawaited(_showCelebration('🏁 FINISH LINE!'));
        } else if (remaining == 1) {
          unawaited(_showCelebration('⚡ ONE MORE!'));
        } else if (remaining <= 3) {
          unawaited(_showCelebration('🔥 SO CLOSE!'));
        } else if (score == 1) {
          unawaited(_showCelebration('🚀 First one!'));
        } else if (widget.level.isBossLevel && score == 3) {
          unawaited(_showCelebration('💀 Halfway there!'));
        } else if (score % 5 == 0) {
          unawaited(_showCelebration('✨ On fire!'));
        } else if (score % 3 == 0) {
          unawaited(_showCelebration('👏 Keep it up!'));
        }

        if (score >= widget.level.pipesToPass) {
          setState(() {
            gameState = 'WIN';
            winFlyOut = true;
          });
          Future<void>.delayed(const Duration(milliseconds: 1200), () {
            _timer?.cancel();
            widget.onWin(eggsDisplay);
          });
          return;
        }
      }
    }

    if (pipes.isNotEmpty && pipes.first.x < -pipeWidth - 30) {
      pipes.removeAt(0);
    }

    // Update feathers
    for (final f in feathers) {
      f.x += f.vx;
      f.y += f.vy;
      f.vy += 0.18; // gravity
      f.rotation += f.rotSpeed;
      f.life -= 0.025;
    }
    feathers.removeWhere((f) => f.life <= 0);

    // Win fly-out: bird zooms right off screen
    if (winFlyOut) {
      winBirdX += 18;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // Spacebar, arrow up, or 'W' triggers jump — any key event type is fine
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.keyW) {
            _jump();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
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
                    birdTier: widget.level.birdTier,
                    birdType: widget.character.birdType,
                    effectClock: effectClock,
                    isBoosted: isBoosted,
                    feathers: feathers,
                    winBirdX: winBirdX + boostBirdX,
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
          // Branding — sits above safe area bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 54,
            right: 12,
            child: const Text(
              'Powered by LookersHub',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (gameState == 'IDLE')
            _CenterOverlay(
              title: 'Level ${widget.level.id}',
              subtitle: widget.level.isBossLevel
                  ? '${getChapter(widget.level.id).emoji} ${getChapter(widget.level.id).name} — BOSS • ${widget.level.pipesToPass} pipes • Pipes move!'
                  : '${getChapter(widget.level.id).emoji} ${getChapter(widget.level.id).name} • ${rankLabel(getLevelRank(widget.level.id))} • ${widget.level.pipesToPass} pipes',
              icon: widget.level.isBossLevel ? Icons.local_fire_department : Icons.rocket_launch,
              tint: widget.level.isBossLevel ? const Color(0xCC2D0A00) : Colors.black45,
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

          // ── Red crash flash ───────────────────────────────────────────────
          if (showCrashFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 80),
                  opacity: showCrashFlash ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.red.withOpacity(0.0),
                          Colors.red.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Speed Boost button (bottom-left, visible while playing) ───────
          if (gameState == 'PLAYING' || gameState == 'IDLE' || gameState == 'COUNTDOWN')
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 22,
              child: GestureDetector(
                onTap: (eggsDisplay >= boostEggCost && !isBoosted && gameState == 'PLAYING')
                    ? _activateBoost
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBoosted
                        ? const Color(0xFFFF6A00)
                        : eggsDisplay >= boostEggCost
                            ? const Color(0xFF1A3A00).withOpacity(0.90)
                            : Colors.black.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isBoosted
                          ? Colors.white
                          : eggsDisplay >= boostEggCost
                              ? const Color(0xFF76FF03)
                              : Colors.white24,
                      width: isBoosted ? 2.0 : eggsDisplay >= boostEggCost ? 1.8 : 1.0,
                    ),
                    boxShadow: isBoosted
                        ? [BoxShadow(color: const Color(0xFFFF6A00).withOpacity(0.6), blurRadius: 12, spreadRadius: 2)]
                        : eggsDisplay >= boostEggCost
                            ? [BoxShadow(color: const Color(0xFF76FF03).withOpacity(0.45), blurRadius: 10, spreadRadius: 1)]
                            : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBoosted ? '⚡ BOOSTED!' : '⚡ Boost',
                        style: TextStyle(
                          color: isBoosted
                              ? Colors.white
                              : eggsDisplay >= boostEggCost
                                  ? const Color(0xFFCCFF90)
                                  : Colors.white30,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!isBoosted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: eggsDisplay >= boostEggCost
                                ? const Color(0xFFFACC15).withOpacity(0.85)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '🥚$boostEggCost',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: eggsDisplay >= boostEggCost ? Colors.black87 : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game Painter — handles all canvas drawing
// ─────────────────────────────────────────────────────────────────────────────

class _GamePainter extends CustomPainter {
  final List<_Star> stars;
  final List<PipeData> pipes;
  final double birdY;
  final double birdVelocity;
  final Color birdColor;
  final Color pipeColor;
  final double gapSize;
  final LevelRank levelRank;
  final int birdTier;
  final int birdType;
  final double effectClock;
  final bool isBoosted;
  final List<_Feather> feathers;
  final double winBirdX;   // >canvasWidth means off-screen

  _GamePainter({
    required this.stars,
    required this.pipes,
    required this.birdY,
    required this.birdVelocity,
    required this.birdColor,
    required this.pipeColor,
    required this.gapSize,
    required this.levelRank,
    required this.birdTier,
    required this.birdType,
    required this.effectClock,
    this.isBoosted = false,
    this.feathers = const [],
    this.winBirdX = 118,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isHard = isHardLevel(levelRank);

    // ── City skyline background ────────────────────────────────────────────
    _drawCityBackground(canvas, size);

    // ── Pipes ──────────────────────────────────────────────────────────────
    final pipePaint = Paint()..color = pipeColor;
    final pipeHighlight = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final pipeEdge = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final pipe in pipes) {
      final gapTop = pipe.topHeight;
      final gapBottom = pipe.topHeight + gapSize;
      final cx = pipe.x + 35; // pipe centre x

      // ── Top pipe ──────────────────────────────────────────────────────────
      final topRect = Rect.fromLTWH(pipe.x, 0, 70, gapTop);
      canvas.drawRRect(RRect.fromRectAndRadius(topRect, const Radius.circular(8)), pipePaint);
      // Highlight stripe on left edge
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x + 6, 0, 8, gapTop), const Radius.circular(4)),
        pipeHighlight,
      );
      // Cap at bottom of top pipe
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x - 4, gapTop - 14, 78, 14), const Radius.circular(6)),
        pipePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x - 4, gapTop - 14, 78, 14), const Radius.circular(6)),
        pipeEdge,
      );

      // ── Bottom pipe ───────────────────────────────────────────────────────
      final botRect = Rect.fromLTWH(pipe.x, gapBottom, 70, 1000);
      canvas.drawRRect(RRect.fromRectAndRadius(botRect, const Radius.circular(8)), pipePaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x + 6, gapBottom, 8, 900), const Radius.circular(4)),
        pipeHighlight,
      );
      // Cap at top of bottom pipe
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x - 4, gapBottom, 78, 14), const Radius.circular(6)),
        pipePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x - 4, gapBottom, 78, 14), const Radius.circular(6)),
        pipeEdge,
      );

      // ── Boss level: moving pipe arrows + glow ─────────────────────────────
      if (isHard && pipe.oscillationAmp > 0) {
        // Determine direction from velocity (sin derivative = cos)
        final movingDown = cos(pipe.oscillationPhase) > 0;
        final arrowColor = movingDown
            ? const Color(0xFFFF3D00).withOpacity(0.9)
            : const Color(0xFF00E5FF).withOpacity(0.9);

        // Glow around gap opening edges
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x - 4, gapTop - 16, 78, 16), const Radius.circular(6)),
          Paint()
            ..color = arrowColor.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(pipe.x - 4, gapBottom, 78, 16), const Radius.circular(6)),
          Paint()
            ..color = arrowColor.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );

        // Arrow pointing direction of movement on both pipes
        final arrowPaint = Paint()
          ..color = arrowColor
          ..style = PaintingStyle.fill;

        // Arrow on top pipe cap
        final ay1 = movingDown ? gapTop - 22 : gapTop - 26;
        final ay2 = movingDown ? gapTop - 14 : gapTop - 18;
        canvas.drawPath(
          Path()
            ..moveTo(cx - 8, movingDown ? ay1 : ay2)
            ..lineTo(cx + 8, movingDown ? ay1 : ay2)
            ..lineTo(cx, movingDown ? ay2 : ay1)
            ..close(),
          arrowPaint,
        );

        // Arrow on bottom pipe cap
        final by1 = movingDown ? gapBottom + 14 : gapBottom + 18;
        final by2 = movingDown ? gapBottom + 18 : gapBottom + 22;
        canvas.drawPath(
          Path()
            ..moveTo(cx - 8, movingDown ? by1 : by2)
            ..lineTo(cx + 8, movingDown ? by1 : by2)
            ..lineTo(cx, movingDown ? by2 : by1)
            ..close(),
          arrowPaint,
        );
      }

      // ── Pipe fire jets (hard levels only) ────────────────────────────────
      if (isHard) {
        _drawPipeFire(canvas, pipe);
      }

      // ── Egg ───────────────────────────────────────────────────────────────
      if (pipe.hasEgg && !pipe.eggCollected) {
        final eggPaint = Paint()..color = const Color(0xFFFACC15);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(pipe.x + 35, pipe.eggY), width: 16, height: 20),
          eggPaint,
        );
        // Egg shine
        canvas.drawOval(
          Rect.fromCenter(center: Offset(pipe.x + 32, pipe.eggY - 3), width: 5, height: 4),
          Paint()..color = Colors.white.withOpacity(0.55),
        );
      }

      // ── Trees on pipe caps ────────────────────────────────────────────────
      _drawPipeTrees(canvas, pipe.x, gapTop, gapBottom, size.height);
    }

    // ── Boost speed lines ──────────────────────────────────────────────────
    if (isBoosted) {
      final linePaint = Paint()
        ..color = const Color(0xFFFFCC00).withOpacity(0.55)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final yOffset = (i - 3.5) * 14.0;
        final xPhase = (effectClock * 6 + i * 0.7) % 1.0;
        final lineLen = 30.0 + sin(effectClock * 8 + i) * 12;
        final startX = 80.0 - xPhase * 60;
        canvas.drawLine(
          Offset(startX, birdY + 18 + yOffset),
          Offset(startX - lineLen, birdY + 18 + yOffset),
          linePaint..color = const Color(0xFFFFCC00).withOpacity(0.55 * (1 - xPhase)),
        );
      }
    }

    // ── Bird — bigger emoji, win fly-out support ────────────────────────────
    // During win fly-out the bird zooms off to the right
    final drawBirdX = winBirdX;
    if (drawBirdX < size.width + 100) {
      canvas.save();
      canvas.translate(drawBirdX, birdY + 18);
      canvas.rotate((birdVelocity * 0.04).clamp(-0.35, 0.45));

      // Tier 1 = 34px, tier 10 = 60px — noticeably bigger than before
      final emojiPx = 34.0 + (birdTier - 1) * 2.9;

      final bp = _GameBirdPainter(
        birdType: birdType,
        birdColor: birdColor,
        effectClock: effectClock,
        levelRank: levelRank,
        emojiSize: emojiPx,
        velocity: birdVelocity,
      );
      bp.drawAt(canvas);
      canvas.restore();
    }

    // ── Feather particles ──────────────────────────────────────────────────
    for (final f in feathers) {
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.rotate(f.rotation);
      final alpha = (f.life * 255).clamp(0, 255).toInt();
      // Feather shape: elongated oval with a quill line
      final featherPaint = Paint()
        ..color = f.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 14),
        featherPaint,
      );
      // Lighter inner vane
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 1), width: 3, height: 9),
        Paint()..color = Colors.white.withAlpha((alpha * 0.5).toInt()),
      );
      // Quill line
      canvas.drawLine(
        const Offset(0, -7), const Offset(0, 7),
        Paint()
          ..color = Colors.white.withAlpha((alpha * 0.7).toInt())
          ..strokeWidth = 1.0,
      );
      canvas.restore();
    }
  }

  /// Draws a city skyline with smooth gradient fades — no hard silhouette edges.
  void _drawCityBackground(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = effectClock;

    // Soft clouds
    for (int i = 0; i < 5; i++) {
      final cx = (w * 0.1 + i * w * 0.22 + t * 5 * (i % 2 == 0 ? 0.25 : 0.45)) % (w + 80) - 40;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 55.0 + i * 20), width: 90 + i * 22.0, height: 30.0),
        Paint()..color = Colors.white.withOpacity(0.06)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // ── Far layer — silhouettes with top-fade (transparency at top → solid at bottom)
    final farWidths  = [28.0,22.0,32.0,18.0,26.0,30.0,20.0,24.0,28.0,22.0,34.0,18.0,26.0,22.0];
    final farHeights = [140.0,100.0,160.0,80.0,120.0,150.0,90.0,110.0,130.0,95.0,165.0,75.0,115.0,88.0];
    double fbx = 0;
    for (int i = 0; i < farWidths.length; i++) {
      final fh = farHeights[i];
      final fx = fbx;
      final fy = h - fh;
      // Gradient: transparent at top of building → semi-transparent at base
      final farGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.22)],
      ).createShader(Rect.fromLTWH(fx, fy, farWidths[i], fh));
      canvas.drawRect(
        Rect.fromLTWH(fx, fy, farWidths[i], fh),
        Paint()..shader = farGrad,
      );
      fbx += farWidths[i] + 3;
    }

    // ── Mid layer — taller buildings, soft fade + faint windows
    const midW = [44.0,36.0,52.0,38.0,48.0,42.0,34.0,50.0,40.0];
    const midH = [200.0,150.0,240.0,170.0,220.0,180.0,140.0,230.0,160.0];
    double mbx = 0;
    for (int bi = 0; bi < midW.length; bi++) {
      final bw = midW[bi];
      final bh = midH[bi];
      final bx = mbx;
      final by = h - bh;
      // Gradient: transparent top → more opaque base
      final midGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.38)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(bx, by, bw, bh));
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), Paint()..shader = midGrad);

      // Soft glowing windows (fewer, more subtle)
      final winOn = Paint()
        ..color = const Color(0xFFFFEB3B).withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      int wc = 0;
      for (double wy = by + bh * 0.25; wy < h - 14; wy += 14.0) {
        for (double wx = bx + 6; wx < bx + bw - 6; wx += 12.0) {
          if ((bi * 11 + wc * 7) % 4 != 0) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 6, 8), winOn);
          }
          wc++;
        }
      }
      // Antenna
      if (bi % 3 == 0) {
        canvas.drawLine(Offset(bx + bw / 2, by), Offset(bx + bw / 2, by - 16),
          Paint()..color = Colors.black.withOpacity(0.35)..strokeWidth = 1.5);
        canvas.drawCircle(Offset(bx + bw / 2, by - 18), 2.5,
          Paint()..color = Colors.red.withOpacity(0.5));
      }
      mbx += bw + 6;
    }

    // ── Soft ground strip with gradient fade ──────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, h - 28, w, 28),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.48)],
        ).createShader(Rect.fromLTWH(0, h - 28, w, 28)),
    );

    _drawGroundTrees(canvas, w, h);
  }

  void _drawGroundTrees(Canvas canvas, double w, double h) {
    final groundY = h - 24.0;
    // 6 trees spaced across the ground, scroll based on effectClock
    for (int i = 0; i < 8; i++) {
      final tx = ((i * 58.0 + effectClock * 3) % (w + 60)) - 30;
      _drawTree(canvas, tx, groundY, scale: 0.7 + (i % 3) * 0.15);
    }
  }

  void _drawTree(Canvas canvas, double cx, double baseY, {double scale = 1.0}) {
    final trunkH = 22.0 * scale;
    final trunkW = 7.0 * scale;
    // Trunk
    canvas.drawRect(
      Rect.fromLTWH(cx - trunkW / 2, baseY - trunkH, trunkW, trunkH),
      Paint()..color = const Color(0xFF5D4037).withOpacity(0.85),
    );
    // Three triangle canopy layers
    final foliagePaint = Paint()..color = const Color(0xFF2E7D32).withOpacity(0.88);
    final foliagePaint2 = Paint()..color = const Color(0xFF388E3C).withOpacity(0.75);
    for (int layer = 0; layer < 3; layer++) {
      final ly = baseY - trunkH - layer * 14.0 * scale;
      final lw = (30.0 - layer * 6.0) * scale;
      final lh = 20.0 * scale;
      canvas.drawPath(
        Path()
          ..moveTo(cx, ly - lh)
          ..lineTo(cx - lw / 2, ly)
          ..lineTo(cx + lw / 2, ly)
          ..close(),
        layer % 2 == 0 ? foliagePaint : foliagePaint2,
      );
    }
  }

  /// Draws pine trees on the pipes — growing INTO the pipe body as if pulled by gravity:
  /// Top pipe: trees grow UPWARD from the pipe cap, rooted at cap, going up into the pipe.
  /// Bottom pipe: trees are FLIPPED (upside-down), rooted at the cap, pointing down into the pipe.
  void _drawPipeTrees(Canvas canvas, double pipeX, double gapTop, double gapBottom, double canvasH) {
    // ── Top pipe: trees grow upward from the cap into the pipe body (normal direction)
    _drawTree(canvas, pipeX + 18, gapTop - 14, scale: 0.52);
    _drawTree(canvas, pipeX + 48, gapTop - 14, scale: 0.44);

    // ── Bottom pipe: trees are FLIPPED — root at cap, grow downward into the pipe body
    canvas.save();
    final flipY = gapBottom + 14;
    canvas.translate(0, flipY * 2);
    canvas.scale(1.0, -1.0);
    _drawTree(canvas, pipeX + 18, flipY, scale: 0.52);
    _drawTree(canvas, pipeX + 48, flipY, scale: 0.44);
    canvas.restore();
  }


  /// Draws animated fire jets erupting from both the top and bottom pipe openings.
  void _drawPipeFire(Canvas canvas, PipeData pipe) {
    final gapTop = pipe.topHeight;
    final gapBottom = pipe.topHeight + gapSize;
    final t = effectClock;

    // Draw a realistic flame jet — direction: 1 = downward, -1 = upward
    void drawJet(double cx, double baseY, double dir) {
      final fl = 18.0 + sin(t * 4.8 + cx * 0.05) * 10 + sin(t * 7.1 + cx * 0.08) * 5;
      final tipY = baseY + dir * fl;
      final wave = sin(t * 6 + cx * 0.04) * 3.5;

      // Outer glow haze
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, baseY + dir * fl * 0.5), width: 22, height: fl * 0.9),
        Paint()
          ..color = const Color(0xFFFF4500).withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Outer flame (dark orange / red-orange)
      final outer = Path()
        ..moveTo(cx - 9, baseY)
        ..cubicTo(cx - 6 + wave, baseY + dir * fl * 0.4,
                  cx + wave * 1.2, baseY + dir * fl * 0.75,
                  cx + wave * 0.5, tipY)
        ..cubicTo(cx + 5 + wave, baseY + dir * fl * 0.75,
                  cx + 6 - wave, baseY + dir * fl * 0.4,
                  cx + 9, baseY)
        ..close();
      canvas.drawPath(outer,
        Paint()
          ..shader = LinearGradient(
            begin: dir > 0 ? Alignment.topCenter : Alignment.bottomCenter,
            end: dir > 0 ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [const Color(0xFFFF4500), const Color(0xFFFF6A00).withOpacity(0.3)],
          ).createShader(Rect.fromPoints(Offset(cx - 9, baseY), Offset(cx + 9, tipY))),
      );

      // Middle flame (orange)
      final mid = Path()
        ..moveTo(cx - 5.5, baseY)
        ..cubicTo(cx - 3 + wave * 0.6, baseY + dir * fl * 0.4,
                  cx + wave * 0.8, baseY + dir * fl * 0.7,
                  cx + wave * 0.3, tipY - dir * fl * 0.1)
        ..cubicTo(cx + 3 + wave * 0.6, baseY + dir * fl * 0.7,
                  cx + 4 - wave * 0.6, baseY + dir * fl * 0.4,
                  cx + 5.5, baseY)
        ..close();
      canvas.drawPath(mid,
        Paint()
          ..shader = LinearGradient(
            begin: dir > 0 ? Alignment.topCenter : Alignment.bottomCenter,
            end: dir > 0 ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [const Color(0xFFFFCC00), const Color(0xFFFF8C00).withOpacity(0.5)],
          ).createShader(Rect.fromPoints(Offset(cx - 6, baseY), Offset(cx + 6, tipY))),
      );

      // White-hot core (near base)
      final coreLen = fl * 0.38;
      final core = Path()
        ..moveTo(cx - 2.5, baseY)
        ..quadraticBezierTo(cx + sin(t * 9 + cx) * 1.5, baseY + dir * coreLen, cx + 2.5, baseY)
        ..close();
      canvas.drawPath(core, Paint()..color = Colors.white.withOpacity(0.82));

      // Embers — 4 per jet
      for (int e = 0; e < 4; e++) {
        final ep = (t * 1.1 + e * 0.25 + cx * 0.003) % 1.0;
        final ex = cx + sin(t * 3 + e * 1.7 + cx * 0.01) * 7;
        final ey = baseY + dir * (ep * fl * 0.95);
        final er = (1.0 - ep) * 2.2 + 0.5;
        canvas.drawCircle(Offset(ex, ey), er,
          Paint()..color = Color.lerp(const Color(0xFFFFDD00), Colors.deepOrange, ep)!.withOpacity((1.0 - ep) * 0.85));
      }
    }

    // Top pipe: 4 jets pointing downward
    for (int i = 0; i < 4; i++) {
      final cx = pipe.x + 8.0 + i * 16.0;
      drawJet(cx, gapTop, 1.0);
    }

    // Bottom pipe: 4 jets pointing upward
    for (int i = 0; i < 4; i++) {
      final cx = pipe.x + 8.0 + i * 16.0;
      drawJet(cx, gapBottom, -1.0);
    }

    // Glowing rim at both pipe openings
    canvas.drawRect(Rect.fromLTWH(pipe.x, gapTop - 2, 70, 4),
        Paint()..color = const Color(0xFFFF6A00).withOpacity(0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawRect(Rect.fromLTWH(pipe.x, gapBottom - 2, 70, 4),
        Paint()..color = const Color(0xFFFF6A00).withOpacity(0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// _GameBirdPainter — draws emoji bird at canvas origin (0,0)
// Each character maps to a real emoji; size scales with birdTier.
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the emoji string for a given birdType (0-7).
String birdEmoji(int birdType) {
  const emojis = ['🐦', '🦋', '🦚', '🦉', '🐦‍⬛', '🦅', '🦜', '🐲'];
  return emojis[birdType.clamp(0, 7)];
}

class _GameBirdPainter {
  final int birdType;
  final Color birdColor;
  final double effectClock;
  final LevelRank levelRank;
  final double emojiSize;
  /// Current vertical velocity — used to vary wing angle (diving vs climbing).
  final double velocity;

  const _GameBirdPainter({
    required this.birdType,
    required this.birdColor,
    required this.effectClock,
    required this.levelRank,
    this.emojiSize = 36,
    this.velocity = 0,
  });

  bool get _isBoss => isHardLevel(levelRank);

  // Colour palettes per character [body, wingDark, wingLight, belly, beak, eye]
  static const _palettes = [
    [0xFF1976D2, 0xFF0D47A1, 0xFF64B5F6, 0xFFE3F2FD, 0xFFFF8F00, 0xFF111111],
    [0xFFAB47BC, 0xFF6A1B9A, 0xFFCE93D8, 0xFFF3E5F5, 0xFFFFD600, 0xFF111111],
    [0xFF00897B, 0xFF004D40, 0xFF4DB6AC, 0xFFE0F2F1, 0xFF795548, 0xFF111111],
    [0xFF8D6E63, 0xFF4E342E, 0xFFBCAAA4, 0xFFEFEBE9, 0xFFFF8F00, 0xFFFFD600],
    [0xFF424242, 0xFF212121, 0xFF757575, 0xFF616161, 0xFF9E9E9E, 0xFFFF1744],
    [0xFF795548, 0xFF3E2723, 0xFFA1887F, 0xFFFFECB3, 0xFFFF6F00, 0xFF111111],
    [0xFF43A047, 0xFF1B5E20, 0xFF81C784, 0xFFF1F8E9, 0xFFE53935, 0xFF111111],
    [0xFF7B1FA2, 0xFF4A148C, 0xFFBA68C8, 0xFFEDE7F6, 0xFFFF6F00, 0xFFFFD600],
  ];

  void drawAt(Canvas canvas) {
    if (_isBoss) {
      final r = emojiSize * 0.55 + sin(effectClock * 3) * 3;
      canvas.drawCircle(Offset.zero, r + 8,
          Paint()..color = const Color(0xFFFF6A00).withOpacity(0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      canvas.drawCircle(Offset.zero, r + 2,
          Paint()..color = const Color(0xFFFF6A00).withOpacity(0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    _drawBird(canvas);
    if (_isBoss) _drawRealisticFire(canvas, emojiSize * 0.4);
  }

  void _drawBird(Canvas canvas) {
    final idx  = birdType.clamp(0, 7);
    final pal  = _palettes[idx];
    final body      = Color(pal[0]);
    final wingDark  = Color(pal[1]);
    final wingLight = Color(pal[2]);
    final belly     = Color(pal[3]);
    final beak      = Color(pal[4]);
    final eye       = Color(pal[5]);

    // r = half the emoji "font size" — all coords in these units
    final r = emojiSize * 0.5;

    // ── Wing flap ─────────────────────────────────────────────────────────────
    // Asymmetric: fast downstroke (snap), slow upstroke (glide)
    final t   = effectClock * 7.0;
    final raw = sin(t);
    final shaped = raw > 0
        ? pow(raw,  0.55).toDouble()
        : -pow(-raw, 0.80).toDouble();
    // Velocity: negative = climbing → push wing further down
    final vBias = (velocity / 15.0).clamp(-0.5, 0.5);
    final flap  = (shaped - vBias).clamp(-1.0, 1.0); // −1 full down, +1 full up

    // The wing tip Y-position relative to body centre.
    // Negative = above body, positive = below.
    // Full down: tip reaches r*1.1 below centre. Full up: r*0.9 above.
    final tipY = flap * r * 1.0;
    // Tip X: always extends behind+above/below the body centre
    final tipX = -r * 0.5;

    // ── Draw far wing first (same motion, slightly muted, peeking out) ────────
    _drawOneWing(canvas, r, tipX * 0.9, tipY * 0.85,
        Color.lerp(wingDark, Colors.black, 0.2)!, wingDark, far: true);

    // ── Body ─────────────────────────────────────────────────────────────────
    // Plump oval torso, head is just the front-top of it
    final bodyRect = Rect.fromCenter(
        center: Offset(r * 0.05, 0), width: r * 1.7, height: r * 1.2);
    canvas.drawOval(bodyRect, Paint()..color = body);

    // Belly highlight
    canvas.drawOval(
        Rect.fromCenter(center: Offset(r * 0.15, r * 0.15),
            width: r * 0.9, height: r * 0.7),
        Paint()..color = belly.withOpacity(0.55));

    // Head
    canvas.drawCircle(Offset(r * 0.7, -r * 0.45), r * 0.48,
        Paint()..color = body);

    // ── Near wing (in front of body) ──────────────────────────────────────────
    _drawOneWing(canvas, r, tipX, tipY, wingLight, wingDark, far: false);

    // ── Tail ─────────────────────────────────────────────────────────────────
    final tailBase = Offset(-r * 0.75, 0);
    final tailTip  = Offset(-r * 1.35, flap * r * 0.15); // tail tilts gently
    final tailPath = Path()
      ..moveTo(tailBase.dx, tailBase.dy - r * 0.22)
      ..quadraticBezierTo(
          (tailBase.dx + tailTip.dx) / 2, tailBase.dy - r * 0.05,
          tailTip.dx, tailTip.dy - r * 0.18)
      ..lineTo(tailTip.dx, tailTip.dy + r * 0.18)
      ..quadraticBezierTo(
          (tailBase.dx + tailTip.dx) / 2, tailBase.dy + r * 0.1,
          tailBase.dx, tailBase.dy + r * 0.22)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = wingDark);
    canvas.drawPath(tailPath,
        Paint()..color = wingLight.withOpacity(0.5)
            ..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // ── Beak ─────────────────────────────────────────────────────────────────
    final beakBase = Offset(r * 0.95, -r * 0.42);
    canvas.drawPath(
      Path()
        ..moveTo(beakBase.dx, beakBase.dy - r * 0.10)
        ..lineTo(beakBase.dx + r * 0.42, beakBase.dy)
        ..lineTo(beakBase.dx, beakBase.dy + r * 0.08)
        ..close(),
      Paint()..color = beak,
    );

    // ── Eye ──────────────────────────────────────────────────────────────────
    final eyeC = Offset(r * 0.82, -r * 0.52);
    canvas.drawCircle(eyeC, r * 0.145, Paint()..color = Colors.white);
    canvas.drawCircle(eyeC.translate(r * 0.02, 0), r * 0.09,
        Paint()..color = eye);
    canvas.drawCircle(eyeC.translate(r * 0.04, -r * 0.04), r * 0.04,
        Paint()..color = Colors.white.withOpacity(0.9));
  }

  /// Draws one wing. The wing is a simple curved shape that rotates around
  /// the body centre — tip moves up and down through [tipY].
  void _drawOneWing(Canvas canvas, double r,
      double tipX, double tipY,
      Color fill, Color edge, {required bool far}) {

    // Wing root sits at the top-centre of the body
    const rootX = 0.0;
    const rootY = 0.0;

    // The wing is drawn as a crescent: leading edge curves to the tip,
    // trailing edge sweeps back creating the classic bird-wing silhouette.
    // All in body-relative coords (centre = Offset.zero).

    // Leading edge control point
    final lcX = rootX - r * 0.25;
    final lcY = rootY + tipY * 0.4 - r * 0.3;

    // Trailing edge: sweeps back from root toward the tail
    final trailRootX = rootX - r * 0.15;
    final trailRootY = rootY + r * 0.12;
    final trailMidX  = tipX + r * 0.12;
    final trailMidY  = tipY + (tipY > 0 ? r * 0.25 : -r * 0.1);

    final wing = Path()
      ..moveTo(rootX, rootY)
      ..quadraticBezierTo(lcX, lcY, tipX, tipY)          // leading edge
      ..quadraticBezierTo(trailMidX, trailMidY,
          trailRootX, trailRootY)                         // trailing edge
      ..close();

    final opacity = far ? 0.65 : 0.92;
    canvas.drawPath(wing, Paint()..color = fill.withOpacity(opacity));
    canvas.drawPath(wing,
        Paint()..color = edge.withOpacity(opacity * 0.7)
            ..style = PaintingStyle.stroke..strokeWidth = 1.1);

    // Primary feather splits near tip (5 short lines)
    if (!far) {
      for (int i = 1; i <= 5; i++) {
        final frac = i / 6.0;
        final fx = tipX * frac;
        final fy = tipY * frac + (rootY + tipY * 0.4 - r * 0.3) * (1 - frac) * 0.4;
        final featherLen = r * (0.22 - i * 0.02);
        canvas.drawLine(
          Offset(fx, fy),
          Offset(fx - featherLen * 0.3, fy + featherLen),
          Paint()..color = edge.withOpacity(0.30)..strokeWidth = 0.9,
        );
      }
    }
  }

  /// Realistic multi-layer fire with turbulence, multiple tongues, embers & heat haze.
  void _drawRealisticFire(Canvas canvas, double originX) {
    final t = effectClock;

    // ── Base flame length — bigger and punchier ────────────────────────────
    final baseLen = emojiSize * 1.6 + sin(t * 3.1) * emojiSize * 0.35;

    // 2. Four turbulent outer flame tongues (dark red-orange)
    for (int i = 0; i < 4; i++) {
      final phase = t * 4.5 + i * 1.6;
      final xNoise = sin(phase) * emojiSize * 0.14;
      final yNoise = cos(phase * 0.8) * emojiSize * 0.22;
      final tipX = originX + baseLen * (0.72 + i * 0.08) + xNoise;
      final tipY = yNoise * (i == 1 ? 0.4 : 1.0);
      final ctrlX = originX + baseLen * 0.42;
      final ctrlY = -emojiSize * (0.26 - i * 0.03) + yNoise * 0.5;
      final w = emojiSize * (0.45 - i * 0.04);

      final tongue = Path()
        ..moveTo(originX, -w * 0.5)
        ..quadraticBezierTo(ctrlX, ctrlY - w * 0.4, tipX, tipY)
        ..quadraticBezierTo(ctrlX, ctrlY + w * 0.55, originX, w * 0.5)
        ..close();
      canvas.drawPath(tongue,
        Paint()
          ..color = const Color(0xFFDD2200).withOpacity(0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // 3. Main flame body — orange with gradient
    final mainLen = baseLen * 0.90;
    final mainWave = sin(t * 5.8) * emojiSize * 0.08;
    final mainPath = Path()
      ..moveTo(originX, -emojiSize * 0.32)
      ..cubicTo(
        originX + mainLen * 0.28, -emojiSize * 0.38 + mainWave,
        originX + mainLen * 0.58, -emojiSize * 0.22 + mainWave,
        originX + mainLen, mainWave * 0.3,
      )
      ..cubicTo(
        originX + mainLen * 0.58, emojiSize * 0.26 + mainWave,
        originX + mainLen * 0.28, emojiSize * 0.36,
        originX, emojiSize * 0.32,
      )
      ..close();
    canvas.drawPath(mainPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFF6500),
            const Color(0xFFFF3D00).withOpacity(0.88),
            const Color(0xFFFF6A00).withOpacity(0.35),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Rect.fromLTWH(originX, -emojiSize * 0.4, mainLen, emojiSize * 0.8)),
    );

    // 4. Bright yellow-orange core
    final coreLen = baseLen * 0.70;
    final coreWave = sin(t * 6.8 + 1.2) * emojiSize * 0.06;
    final corePath = Path()
      ..moveTo(originX, -emojiSize * 0.18)
      ..cubicTo(
        originX + coreLen * 0.32, -emojiSize * 0.22 + coreWave,
        originX + coreLen * 0.62, -emojiSize * 0.12 + coreWave,
        originX + coreLen, coreWave * 0.2,
      )
      ..cubicTo(
        originX + coreLen * 0.62, emojiSize * 0.15 + coreWave,
        originX + coreLen * 0.32, emojiSize * 0.20,
        originX, emojiSize * 0.18,
      )
      ..close();
    canvas.drawPath(corePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFFE000),
            const Color(0xFFFFAA00),
            const Color(0xFFFF7700).withOpacity(0.25),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(originX, -emojiSize * 0.22, coreLen, emojiSize * 0.44)),
    );

    // 5. White-hot near-mouth core
    final hotLen = baseLen * 0.38;
    final hotPath = Path()
      ..moveTo(originX, -emojiSize * 0.08)
      ..quadraticBezierTo(originX + hotLen * 0.5, sin(t * 8) * emojiSize * 0.05, originX + hotLen, 0)
      ..quadraticBezierTo(originX + hotLen * 0.5, emojiSize * 0.08, originX, emojiSize * 0.08)
      ..close();
    canvas.drawPath(hotPath,
      Paint()
        ..color = Colors.white.withOpacity(0.92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // 6. Ember/spark particles drifting forward and up
    for (int e = 0; e < 7; e++) {
      final ep = (t * 0.9 + e * 0.143) % 1.0;
      final ex = originX + baseLen * 0.25 + ep * baseLen * 1.0;
      final ey = sin(t * 3.5 + e * 1.4) * emojiSize * 0.4
               + sin(t * 1.8 + e * 0.7) * emojiSize * 0.12
               - ep * emojiSize * 0.3;
      final er = (1.0 - ep) * emojiSize * 0.09 + 1.2;
      if (ep < 0.88) {
        canvas.drawCircle(
          Offset(ex, ey),
          er,
          Paint()
            ..color = Color.lerp(const Color(0xFFFFEE00), const Color(0xFFFF4400), ep)!
                .withOpacity((1.0 - ep).clamp(0, 1) * 0.95),
        );
      }
    }

    // 7. Extra glowing dot right at the origin (fire source)
    canvas.drawCircle(
      Offset(originX, 0),
      emojiSize * 0.14,
      Paint()
        ..color = Colors.white.withOpacity(0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }


}

// ─── Shop bird preview widget ─────────────────────────────────────────────────
class _ShopBirdPreview extends StatefulWidget {
  final Character character;
  const _ShopBirdPreview({required this.character});
  @override
  State<_ShopBirdPreview> createState() => _ShopBirdPreviewState();
}

class _ShopBirdPreviewState extends State<_ShopBirdPreview> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _ShopBirdCanvas(
          birdType: widget.character.birdType,
          birdColor: widget.character.color,
          clock: _ctrl.value * 2 * pi,
        ),
      ),
    );
  }
}

class _ShopBirdCanvas extends CustomPainter {
  final int birdType;
  final Color birdColor;
  final double clock;
  const _ShopBirdCanvas({required this.birdType, required this.birdColor, required this.clock});
  @override
  void paint(Canvas canvas, Size size) {
    // Center bird with gentle bob; scale emoji to fill available space nicely
    final emojiSz = (size.shortestSide * 0.80).clamp(40.0, 80.0);
    canvas.translate(size.width / 2, size.height / 2 + sin(clock) * 5);
    final painter = _GameBirdPainter(
      birdType: birdType,
      birdColor: birdColor,
      effectClock: clock,
      levelRank: LevelRank.easy,
      emojiSize: emojiSz,
      velocity: sin(clock * 0.5) * 3, // gentle idle flap cycle
    );
    painter.drawAt(canvas);
  }
  @override
  bool shouldRepaint(_ShopBirdCanvas old) => old.clock != clock;
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD, overlays, and supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

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
              style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
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

// ─────────────────────────────────────────────────────────────────────────────
// Star data
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  double x;
  double y;
  double size;
  double speed;

  _Star(this.x, this.y, this.size, this.speed);
}

class _Feather {
  double x, y, vx, vy, rotation, rotSpeed, life;
  final Color color;
  _Feather({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.rotation, required this.rotSpeed,
    required this.color, required this.life,
  });
}