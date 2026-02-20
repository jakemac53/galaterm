import 'dart:async';
import 'package:nocterm/nocterm.dart';

import 'enemy_formation.dart';
import 'game_state.dart';
import 'player.dart';
import 'constants.dart';

class GalatermApp extends StatefulComponent {
  const GalatermApp({super.key});

  @override
  State<GalatermApp> createState() => _GalatermAppState();
}

class _GalatermAppState extends State<GalatermApp> {
  late GameState _gameState;
  late Player _player;
  bool _running = true;
  final List<double> _frameTimes = [];
  double _fps = 0;
  double _avgFrameTime = 0;
  bool _paused = false;

  final int _width = 80;
  final int _height = 40;

  int _levelNumber = 1;
  late Iterator<EnemyFormation> _levels;

  Iterable<EnemyFormation> _generateLevels() sync* {
    int level = 1;
    while (true) {
      yield EnemyFormation(
        rows: 3,
        cols: 8,
        speed: perFrame(2.0 + (level - 1) * 0.5),
        fireRatePerSecond: 0.3 + (level - 1) * 0.2,
        divingSpeed: 6.0 + (level - 1) * 2.0,
        returnSpeed: 8.0 + (level - 1) * 1.5,
      );
      level++;
    }
  }

  @override
  void initState() {
    super.initState();
    _levels = _generateLevels().iterator;
    _levels.moveNext();
    _gameState = GameState(width: _width, height: _height);
    _player = Player(x: (_width ~/ 2).toDouble(), y: (_height - 2).toDouble());
    _gameState.addEntity(_player);
    _gameState.addEntity(_levels.current);
    // Initialize the entities immediately so they render on frame 1
    _gameState.tick();

    _runGameLoop();
  }

  void _nextLevel() {
    setState(() {
      _levelNumber++;
      _levels.moveNext();
      // Keep player but clear other entities? No, GameState needs careful reset.
      // Easiest is to keep the current GameState score and player health but reset entities.
      final oldScore = _gameState.score;
      final oldGalabucks = _gameState.galabucks;
      final oldBombs = _gameState.bombs;
      final oldHealth = _player.health;

      _gameState = GameState(width: _width, height: _height);
      _gameState.score = oldScore;
      _gameState.galabucks = oldGalabucks;
      _gameState.bombs = oldBombs;

      // Reuse the same player instance to keep all powerup states and shield health
      _player.x = (_width ~/ 2).toDouble();
      _player.y = (_height - 2).toDouble();
      _player.health = oldHealth;
      // Clear movement targets for the new level
      _player.moveTo(_player.x, _player.y); 

      _gameState.addEntity(_player);
      _gameState.addEntity(_levels.current);
      _gameState.tick();
    });
  }

  void _resetGame() {
    setState(() {
      _levelNumber = 1;
      _levels = _generateLevels().iterator;
      _levels.moveNext();
      _gameState = GameState(width: _width, height: _height);
      _player = Player(
        x: (_width ~/ 2).toDouble(),
        y: (_height - 2).toDouble(),
      );
      _gameState.addEntity(_player);
      _gameState.addEntity(_levels.current);
      // Initialize the entities immediately so they render on frame 1
      _gameState.tick();
    });
  }

  Future<void> _runGameLoop() async {
    final sw = Stopwatch();
    while (_running) {
      sw.reset();
      sw.start();

      if (!mounted) break;

      setState(() {
        if (!_gameState.isGameOver && !_gameState.isLevelComplete && !_paused) {
          _gameState.tick();
        }
      });

      final elapsedMs = sw.elapsedMicroseconds / 1000.0;
      _frameTimes.add(elapsedMs);
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }

      if (_frameTimes.isNotEmpty) {
        _avgFrameTime =
            _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        // Use 16ms as the baseline for FPS if we are within budget
        final frameDuration = _avgFrameTime > 16.0 ? _avgFrameTime : 16.0;
        _fps = 1000.0 / frameDuration;
      }

      final remaining = 16 - sw.elapsedMilliseconds;
      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      } else {
        // Yield to allow other events to process even if we are over budget
        await Future.delayed(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _running = false;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // We create a lookup map to quickly find entities by their (x, y) coordinates.
    // In a sparse grid, this is much faster than iterating over entities on every cell rendering.
    final charMap = <String, String>{};
    final colorMap = <String, Color?>{};
    final bgMap = <String, Color?>{};
    for (final e in _gameState.entities) {
      for (final active in e.activeEntities) {
        if (active.health > 0) {
          for (int dy = 0; dy < active.height; dy++) {
            for (int dx = 0; dx < active.width; dx++) {
              if (active.lines[dy].length > dx) {
                final char = active.lines[dy][dx];
                if (char != ' ') {
                  final key = '${active.gridX + dx},${active.gridY + dy}';
                  charMap[key] = char;
                  colorMap[key] = active.color;
                  bgMap[key] = active.backgroundColor;
                }
              }
            }
          }
        }
      }
    }

    return NoctermApp(
      title: 'Galaterm',
      child: Focusable(
        focused: true,
        onKeyEvent: (event) {
          final key = event.character?.toLowerCase();
          if (key == 'q') {
            shutdownApp();
            return true;
          }
          if (key == 'p' &&
              !_gameState.isGameOver &&
              !_gameState.isLevelComplete) {
            setState(() {
              _paused = !_paused;
            });
            return true;
          }

          if (_gameState.isGameOver || _gameState.isLevelComplete || _paused) {
            return false;
          }

          if (event.logicalKey == LogicalKey.space || event.character == ' ') {
            _player.fire(_gameState);
            return true;
          }
          if (event.character?.toLowerCase() == 'b') {
            _player.useBomb(_gameState);
            return true;
          }
          return false;
        },
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_gameState.isGameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: BoxBorder.all(style: BoxBorderStyle.double),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'G A M E   O V E R',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF0000),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text('Final Score: ${_gameState.score}'),
                            const SizedBox(height: 1),
                            Text('Levels Cleared: ${_levelNumber - 1}'),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () {
                                _resetGame();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  border: BoxBorder.all(
                                    style: BoxBorderStyle.rounded,
                                  ),
                                  color: const Color(0xFF333333),
                                ),
                                child: const Text(' RESTART '),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_gameState.isLevelComplete)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: BoxBorder.all(style: BoxBorderStyle.double),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'LEVEL COMPLETE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00FF00),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text('Level $_levelNumber Cleared!'),
                            const SizedBox(height: 1),
                            Text('Galabucks: ${_gameState.galabucks}'),
                            const SizedBox(height: 2),
                            const Text(
                              '--- U P G R A D E S ---',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 1),
                            _buildUpgradeRow(
                              'Engines',
                              'Speed +2',
                              (_player.speedUpgradeLevel + 1) * 500,
                              () => _buyUpgrade('speed'),
                            ),
                            _buildUpgradeRow(
                              'Cannons',
                              'Dmg +5',
                              (_player.bulletStrengthUpgradeLevel + 1) * 1000,
                              () => _buyUpgrade('bullet'),
                            ),
                            _buildUpgradeRow(
                              'Armor',
                              'HP +25',
                              (_player.armorUpgradeLevel + 1) * 750,
                              () => _buyUpgrade('armor'),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () {
                                _nextLevel();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  border: BoxBorder.all(
                                    style: BoxBorderStyle.rounded,
                                  ),
                                  color: const Color(0xFF333333),
                                ),
                                child: const Text(' NEXT LEVEL '),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_paused)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: BoxBorder.all(style: BoxBorderStyle.double),
                          color: const Color(0xFF222222),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'P A U S E D',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                            const SizedBox(height: 1),
                            const Text('Press "p" to Resume'),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _paused = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  border: BoxBorder.all(
                                    style: BoxBorderStyle.rounded,
                                  ),
                                  color: const Color(0xFF333333),
                                ),
                                child: const Text(' RESUME '),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_height, (y) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_width, (x) {
                          return MouseRegion(
                            onHover: (event) {
                              final targetX = (x - (_player.width ~/ 2))
                                  .toDouble();
                              final targetY = (y - (_player.height ~/ 2))
                                  .toDouble();
                              _player.moveTo(targetX, targetY);
                            },
                            onEnter: (event) {
                              final targetX = (x - (_player.width ~/ 2))
                                  .toDouble();
                              final targetY = (y - (_player.height ~/ 2))
                                  .toDouble();
                              _player.moveTo(targetX, targetY);
                            },
                            child: Text(
                              charMap['$x,$y'] ?? ' ',
                              style: TextStyle(
                                color: colorMap['$x,$y'],
                                backgroundColor: bgMap['$x,$y'],
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 30,
                        child: ProgressBar(
                          value: (_player.health / _player.maxHealth.toDouble())
                              .clamp(0.0, 1.0),
                          valueColor: _player.health > (_player.maxHealth * 0.2)
                              ? const Color(0xFF00FF00)
                              : const Color(0xFFFF0000),
                          backgroundColor: const Color(0xFF333333),
                          showPercentage: false,
                          label:
                              'Health: ${_player.health}/${_player.maxHealth}',
                        ),
                      ),
                      Text(
                        'Score: ${_gameState.score} | Galabucks: ${_gameState.galabucks} | Bombs: ${_gameState.bombs}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'FPS: ${_fps.toStringAsFixed(1)} | Frame: ${_avgFrameTime.toStringAsFixed(2)}ms',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Use mouse to move. SPACE: fire. B: bomb. P: pause. Q: quit.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _buyUpgrade(String type) {
    setState(() {
      if (type == 'speed') {
        int cost = (_player.speedUpgradeLevel + 1) * 500;
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.speedUpgradeLevel++;
        }
      } else if (type == 'bullet') {
        int cost = (_player.bulletStrengthUpgradeLevel + 1) * 1000;
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.bulletStrengthUpgradeLevel++;
        }
      } else if (type == 'armor') {
        int cost = (_player.armorUpgradeLevel + 1) * 750;
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.armorUpgradeLevel++;
          _player.health = _player.maxHealth;
        }
      }
    });
  }

  Component _buildUpgradeRow(
    String name,
    String effect,
    int cost,
    VoidCallback onBuy,
  ) {
    final canAfford = _gameState.galabucks >= cost;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 12, child: Text(name)),
        const SizedBox(width: 1),
        SizedBox(width: 10, child: Text(effect)),
        const SizedBox(width: 1),
        GestureDetector(
          onTap: canAfford ? onBuy : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: canAfford
                  ? const Color(0xFF004400)
                  : const Color(0xFF440000),
            ),
            child: Text('BUY: $cost'),
          ),
        ),
      ],
    );
  }
}
