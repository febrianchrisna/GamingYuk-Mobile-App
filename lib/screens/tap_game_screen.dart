import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:toko_game/utils/constants.dart';

class TapGameScreen extends StatefulWidget {
  const TapGameScreen({super.key});

  @override
  State<TapGameScreen> createState() => _TapGameScreenState();
}

class _TapGameScreenState extends State<TapGameScreen> {
  int _score = 0;
  int _level = 1;
  int _timeLeft = 30;
  int _targetsNeeded = 10; // Targets needed to complete level
  int _targetsPopped = 0;
  bool _isPlaying = false;
  Timer? _gameTimer;
  Timer? _spawnTimer;

  final List<BubbleTarget> _bubbles = [];
  final Random _random = Random();

  // Accelerometer values for physics
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Game settings that change with level
  double _spawnInterval = 1.5; // seconds
  double _bubbleSize = 80.0;
  double _bubbleSpeed = 1.0;
  int _maxBubbles = 5;

  // Physics settings
  static const double _gravity = 0.5;
  static const double _friction = 0.98;
  static const double _tiltSensitivity = 0.3;

  @override
  void initState() {
    super.initState();
    _startAccelerometerListening();
    _updateLevelSettings();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startAccelerometerListening() {
    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerX = event.x;
        _accelerometerY = event.y;
      });
    });
  }

  void _updateLevelSettings() {
    // Cap level at 10 for balanced difficulty
    int effectiveLevel = min(_level, 10);

    // Progressive difficulty scaling for levels 1-10
    _targetsNeeded = 5 + (effectiveLevel - 1) * 2; // Level 1: 5, Level 10: 23
    _spawnInterval = max(0.4,
        1.2 - (effectiveLevel - 1) * 0.08); // Level 1: 1.2s, Level 10: 0.48s
    _bubbleSize = max(30.0,
        80.0 - (effectiveLevel - 1) * 5.0); // Level 1: 80px, Level 10: 35px
    _bubbleSpeed =
        1.0 + (effectiveLevel - 1) * 0.2; // Level 1: 1.0x, Level 10: 2.8x
    _maxBubbles = min(8, 3 + (effectiveLevel - 1)); // Level 1: 3, Level 10: 8

    // Calculate time with better scaling for higher levels
    double baseTime =
        _targetsNeeded * _spawnInterval * 1.8; // More generous buffer
    int levelBonus =
        (effectiveLevel - 1) * 3; // More time bonus for harder levels
    _timeLeft = max(
        20, baseTime.ceil() + levelBonus + 15); // Minimum 20s, plus 15s base
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _level = 1;
      _targetsPopped = 0;
      _isPlaying = true;
      _bubbles.clear();
    });

    _updateLevelSettings();
    _addBubble();

    // Game countdown timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });

      if (_timeLeft <= 0) {
        _endGame(false); // Time's up
      }
    });

    // Physics update timer (60 FPS)
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _updatePhysics();
    });

    _startSpawnTimer();
  }

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (_spawnInterval * 1000).toInt()),
      (timer) {
        if (_isPlaying && _bubbles.length < _maxBubbles) {
          _addBubble();
        }
      },
    );
  }

  void _updatePhysics() {
    if (!_isPlaying) return;

    final size = MediaQuery.of(context).size;

    setState(() {
      for (var i = _bubbles.length - 1; i >= 0; i--) {
        final bubble = _bubbles[i];

        // Apply accelerometer-based tilt forces
        double tiltForceX = _accelerometerY * _tiltSensitivity; // Y becomes X
        double tiltForceY = _accelerometerX * _tiltSensitivity; // X becomes Y

        // Update velocity with tilt forces and gravity
        double newVelX = bubble.velocityX + tiltForceX;
        double newVelY = bubble.velocityY + _gravity + tiltForceY;

        // Apply friction
        newVelX *= _friction;
        newVelY *= _friction;

        // Update position
        double newX = bubble.position.dx + newVelX * _bubbleSpeed;
        double newY = bubble.position.dy + newVelY * _bubbleSpeed;

        // Bounce off walls
        if (newX < 0 || newX > size.width - bubble.size) {
          newVelX = -newVelX * 0.7; // Dampen bounce
          newX = newX < 0 ? 0 : size.width - bubble.size;
        }

        if (newY < 0 || newY > size.height - bubble.size - 100) {
          newVelY = -newVelY * 0.7; // Dampen bounce
          newY = newY < 0 ? 0 : size.height - bubble.size - 100;
        }

        // Update bubble
        _bubbles[i] = bubble.copyWith(
          position: Offset(newX, newY),
          velocityX: newVelX,
          velocityY: newVelY,
        );

        // Remove bubbles that are out of bounds for too long
        if (newY > size.height + 100) {
          _bubbles.removeAt(i);
        }
      }
    });
  }

  void _addBubble() {
    if (_bubbles.length >= _maxBubbles) return;

    final size = MediaQuery.of(context).size;

    // Random spawn position at top
    final position = Offset(
      _random.nextDouble() * (size.width - _bubbleSize),
      -_bubbleSize, // Start above screen
    );

    // Random initial velocity
    final velocityX = (_random.nextDouble() * 2 - 1) * 2; // -2 to 2
    final velocityY = _random.nextDouble() * 2; // 0 to 2 (downward)

    // Random bubble color and points
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink
    ];
    final color = colors[_random.nextInt(colors.length)];
    final points = _random.nextInt(3) + 1; // 1-3 points

    setState(() {
      _bubbles.add(
        BubbleTarget(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: position,
          size: _bubbleSize,
          color: color,
          velocityX: velocityX,
          velocityY: velocityY,
          points: points,
        ),
      );
    });
  }

  void _tapBubble(BubbleTarget bubble) {
    if (!_isPlaying) return;

    setState(() {
      _bubbles.removeWhere((b) => b.id == bubble.id);
      _score += bubble.points;
      _targetsPopped++;
    });

    // Check if level completed
    if (_targetsPopped >= _targetsNeeded) {
      _completeLevel();
    }
  }

  void _completeLevel() {
    // Check if reached max level
    if (_level >= 10) {
      _endGame(true); // Victory condition
      return;
    }

    setState(() {
      _level++;
      _targetsPopped = 0;
      _bubbles.clear();
    });

    _updateLevelSettings();
    _startSpawnTimer(); // Restart spawning with new settings

    // Show level completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_level <= 10
            ? 'Level ${_level - 1} completed! Level $_level: $_targetsNeeded targets in ${_timeLeft}s'
            : 'All levels completed! You are a Bubble Master!'),
        backgroundColor:
            _level <= 10 ? Colors.green : const Color(0xFFFFD700), // Gold color
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _endGame(bool completed) {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();

    setState(() {
      _isPlaying = false;
    });

    // Show game over dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(completed && _level > 10
            ? 'Congratulations!'
            : completed
                ? 'Level Complete!'
                : 'Game Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completed && _level > 10
                  ? Icons.emoji_events
                  : completed
                      ? Icons.star
                      : Icons.timer_off,
              color: completed && _level > 10
                  ? const Color(0xFFFFD700) // Gold color
                  : completed
                      ? Colors.amber
                      : Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            if (completed && _level > 10)
              const Text(
                'You completed all 10 levels!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Final Score: $_score',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Level Reached: ${min(_level, 10)}${_level > 10 ? ' (MAX)' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreMessage(_score, _level),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  String _getScoreMessage(int score, int level) {
    if (level > 10) {
      return 'Incredible! You conquered all levels and became a Bubble Master!';
    } else if (score >= 100) {
      return 'Excellent! You\'re on your way to becoming a bubble master!';
    } else if (score >= 50) {
      return 'Great job! Keep pushing to reach level 10!';
    } else if (score >= 25) {
      return 'Good progress! Practice tilting your device for better control!';
    } else {
      return 'Nice try! Tilt your device to move bubbles and aim for level 10!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Tap Game'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Game stats
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Score
                Column(
                  children: [
                    const Text(
                      'Score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),

                // Level
                Column(
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_level',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                // Progress
                Column(
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_targetsPopped/$_targetsNeeded',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                // Time
                Column(
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 10 ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Game area
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF87CEEB), // Sky blue light
                        Color(0xFF6CB4EE), // Sky blue dark
                      ],
                    ),
                  ),
                ),

                // Bubbles
                ..._bubbles.map((bubble) => Positioned(
                      left: bubble.position.dx,
                      top: bubble.position.dy,
                      child: GestureDetector(
                        onTap: () => _tapBubble(bubble),
                        child: Container(
                          width: bubble.size,
                          height: bubble.size,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                bubble.color.withValues(alpha: 0.8),
                                bubble.color.withValues(alpha: 0.4),
                                bubble.color.withValues(alpha: 0.1),
                              ],
                              stops: const [0.3, 0.7, 1.0],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: bubble.color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '+${bubble.points}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),

                // Start game overlay
                if (!_isPlaying)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Bubble Tap Game',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pop the bubbles as they float!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tilt your device to move bubbles around!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete levels by popping enough bubbles!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Start Game',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Accelerometer debug info
                if (_isPlaying)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Text(
                        'Tilt: X:${_accelerometerX.toStringAsFixed(1)} Y:${_accelerometerY.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleTarget {
  final String id;
  final Offset position;
  final double size;
  final Color color;
  final double velocityX;
  final double velocityY;
  final int points;

  BubbleTarget({
    required this.id,
    required this.position,
    required this.size,
    required this.color,
    required this.velocityX,
    required this.velocityY,
    required this.points,
  });

  BubbleTarget copyWith({
    String? id,
    Offset? position,
    double? size,
    Color? color,
    double? velocityX,
    double? velocityY,
    int? points,
  }) {
    return BubbleTarget(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      points: points ?? this.points,
    );
  }
}
