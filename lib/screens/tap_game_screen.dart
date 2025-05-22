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
  int _timeLeft = 30;
  bool _isPlaying = false;
  Timer? _gameTimer;
  Timer? _spawnTimer;
  
  final List<GameTarget> _targets = [];
  final Random _random = Random();
  
  // Accelerometer values
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _accelerometerZ = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Game settings
  double _spawnInterval = 1.0; // seconds
  double _targetSize = 70.0;
  double _targetSpeed = 1.0;
  
  @override
  void initState() {
    super.initState();
    _startAccelerometerListening();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
  
  void _startAccelerometerListening() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerX = event.x;
        _accelerometerY = event.y;
        _accelerometerZ = event.z;
        
        // Adjust game difficulty based on device movement
        final movement = sqrt(pow(_accelerometerX, 2) + pow(_accelerometerY, 2) + pow(_accelerometerZ, 2));
        
        if (movement > 15) {
          // Fast movement - make game harder
          _targetSpeed = 2.0;
          _spawnInterval = 0.7;
          _targetSize = 60.0;
        } else if (movement > 10) {
          // Medium movement
          _targetSpeed = 1.5;
          _spawnInterval = 0.85;
          _targetSize = 65.0;
        } else {
          // Slow or no movement - normal difficulty
          _targetSpeed = 1.0;
          _spawnInterval = 1.0;
          _targetSize = 70.0;
        }
      });
    });
  }
  
  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _targets.clear();
    });
    
    // Add initial targets
    _addTarget();
    
    // Start game timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
    
    // Start target spawn timer
    _startSpawnTimer();
  }
  
  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (_spawnInterval * 1000).toInt()),
      (timer) {
        if (_isPlaying) {
          _addTarget();
          
          // Move existing targets
          _moveTargets();
        }
      },
    );
  }
  
  void _moveTargets() {
    setState(() {
      for (var i = _targets.length - 1; i >= 0; i--) {
        final target = _targets[i];
        
        // Check if target should be removed (out of bounds)
        if (target.position.dx < -target.size ||
            target.position.dx > MediaQuery.of(context).size.width ||
            target.position.dy < -target.size ||
            target.position.dy > MediaQuery.of(context).size.height) {
          _targets.removeAt(i);
          continue;
        }
        
        // Move the target
        _targets[i] = target.copyWith(
          position: Offset(
            target.position.dx + target.velocity.dx * _targetSpeed,
            target.position.dy + target.velocity.dy * _targetSpeed,
          ),
        );
      }
    });
  }
  
  void _addTarget() {
    if (_targets.length >= 10) return; // Limit max targets
    
    final size = MediaQuery.of(context).size;
    
    // Randomize position
    final position = Offset(
      _random.nextDouble() * (size.width - _targetSize),
      _random.nextDouble() * (size.height - _targetSize - 100) + 80, // Avoid appbar
    );
    
    // Randomize velocity (direction and speed)
    final velocity = Offset(
      (_random.nextDouble() * 2 - 1) * 3, // -3 to 3
      (_random.nextDouble() * 2 - 1) * 3, // -3 to 3
    );
    
    // Randomize color
    final color = Color.fromRGBO(
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      1,
    );
    
    setState(() {
      _targets.add(
        GameTarget(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: position,
          size: _targetSize,
          color: color,
          velocity: velocity,
          points: _random.nextInt(3) + 1, // 1-3 points
        ),
      );
    });
  }
  
  void _tapTarget(GameTarget target) {
    if (!_isPlaying) return;
    
    setState(() {
      _targets.removeWhere((t) => t.id == target.id);
      _score += target.points;
    });
  }
  
  void _endGame() {
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
        title: const Text('Game Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Your score: $_score',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreMessage(_score),
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
  
  String _getScoreMessage(int score) {
    if (score >= 30) {
      return 'Wow! Amazing performance!';
    } else if (score >= 20) {
      return 'Great job! You have quick reflexes!';
    } else if (score >= 10) {
      return 'Good effort! Keep practicing!';
    } else {
      return 'Nice try! You\'ll do better next time!';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap Game'),
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
                  color: Colors.black.withOpacity(0.05),
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
                
                // Time
                Column(
                  children: [
                    const Text(
                      'Time Left',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_timeLeft s',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 10 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                
                // Level
                Column(
                  children: [
                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _targetSpeed >= 2.0
                          ? 'Hard'
                          : _targetSpeed >= 1.5
                              ? 'Medium'
                              : 'Easy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _targetSpeed >= 2.0
                            ? Colors.red
                            : _targetSpeed >= 1.5
                                ? Colors.orange
                                : Colors.green,
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                
                // Game targets
                ..._targets.map((target) => Positioned(
                  left: target.position.dx,
                  top: target.position.dy,
                  child: GestureDetector(
                    onTap: () => _tapTarget(target),
                    child: Container(
                      width: target.size,
                      height: target.size,
                      decoration: BoxDecoration(
                        color: target.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '+${target.points}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                    color: Colors.black.withOpacity(0.7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tap Game',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap the circles as they appear!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tilt your device to change difficulty!',
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
                
                // Accelerometer debug info (for testing)
                if (_isPlaying)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        'Movement: ${sqrt(pow(_accelerometerX, 2) + pow(_accelerometerY, 2) + pow(_accelerometerZ, 2)).toStringAsFixed(1)}',
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

class GameTarget {
  final String id;
  final Offset position;
  final double size;
  final Color color;
  final Offset velocity;
  final int points;

  GameTarget({
    required this.id,
    required this.position,
    required this.size,
    required this.color,
    required this.velocity,
    required this.points,
  });

  GameTarget copyWith({
    String? id,
    Offset? position,
    double? size,
    Color? color,
    Offset? velocity,
    int? points,
  }) {
    return GameTarget(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      velocity: velocity ?? this.velocity,
      points: points ?? this.points,
    );
  }
}
