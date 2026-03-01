import 'dart:async';
import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'enemy_formation.dart';
import 'game_state.dart';
import 'player.dart';
import 'constants.dart';
import 'omega_laser.dart';

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

  final int _width = 120;
  final int _height = 40;

  int _levelNumber = 1;
  late Iterator<EnemyFormation> _levels;
  final List<String> _levelUpgrades = [];

  Iterable<EnemyFormation> _generateLevels() sync* {
    int level = 1;
    final rand = Random();
    while (true) {
      if (level % 5 == 0) {
        final bossType = (level ~/ 5 - 1) % 3;
        final healthMultiplier = 1 + ((level - 1) ~/ 5);
        if (bossType == 1) {
          yield EnemyFormation.hydraBoss(
            x: 50,
            y: 5,
            healthMultiplier: healthMultiplier,
          );
        } else if (bossType == 2) {
          yield EnemyFormation.helicopterBoss(
            x: 44,
            y: 5,
            healthMultiplier: healthMultiplier,
          );
        } else {
          yield EnemyFormation.boss(
            x: 49,
            y: 5,
            healthMultiplier: healthMultiplier,
          );
        }
      } else {
        final speed = perFrame(2.0 + (level - 1) * 0.5);
        final fireRatePerSecond = 0.3 + (level - 1) * 0.2;
        final divingSpeed = 6.0 + (level - 1) * 2.0;
        final returnSpeed = 8.0 + (level - 1) * 1.5;
        final healthMultiplier = 1 + ((level - 1) ~/ 5);

        final randInt = rand.nextInt(4);
        if (randInt == 0) {
          yield EnemyFormation.vShape(
            speed: speed,
            fireRatePerSecond: fireRatePerSecond,
            divingSpeed: divingSpeed,
            returnSpeed: returnSpeed,
            healthMultiplier: healthMultiplier,
          );
        } else if (randInt == 1) {
          yield EnemyFormation.diamond(
            speed: speed,
            fireRatePerSecond: fireRatePerSecond,
            divingSpeed: divingSpeed,
            returnSpeed: returnSpeed,
            healthMultiplier: healthMultiplier,
          );
        } else if (randInt == 2) {
          yield EnemyFormation.twinColumns(
            speed: speed,
            fireRatePerSecond: fireRatePerSecond,
            divingSpeed: divingSpeed,
            returnSpeed: returnSpeed,
            healthMultiplier: healthMultiplier,
          );
        } else {
          yield EnemyFormation(
            rows: 3,
            cols: 8,
            speed: speed,
            fireRatePerSecond: fireRatePerSecond,
            divingSpeed: divingSpeed,
            returnSpeed: returnSpeed,
            healthMultiplier: healthMultiplier,
          );
        }
      }
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
      _levelUpgrades.clear();
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
      _levelUpgrades.clear();
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

  Color _getHealthColor(double ratio) {
    if (ratio >= 0.5) {
      // 1.0 (Green) to 0.5 (Yellow)
      // r scales from 0 (at 1.0) to 255 (at 0.5)
      final r = (255 * (1.0 - ratio) * 2).clamp(0, 255).toInt();
      return Color.fromARGB(255, r, 255, 0);
    } else {
      // 0.5 (Yellow) to 0.0 (Red)
      // g scales from 255 (at 0.5) to 0 (at 0.0)
      final g = (255 * (ratio * 2)).clamp(0, 255).toInt();
      return Color.fromARGB(255, 255, g, 0);
    }
  }

  @override
  Component build(BuildContext context) {
    // We create a lookup map to quickly find entities by their (x, y) coordinates.
    // In a sparse grid, this is much faster than iterating over entities on every cell rendering.
    final charMap = <String, String>{};
    final colorMap = <String, Color?>{};
    final bgMap = <String, Color?>{};
    
    final activeEntities = _gameState.entities
        .expand((e) => e.activeEntities)
        .where((active) => active.health > 0)
        .toList();

    // Sort ascending by zIndex, so higher zIndex overwrites lower
    activeEntities.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final active in activeEntities) {
      for (int dy = 0; dy < active.height; dy++) {
        final line = active.lines[dy];
        final runes = line.runes.toList();
        for (int dx = 0; dx < runes.length; dx++) {
          final char = String.fromCharCode(runes[dx]);
          if (char != ' ' || active.backgroundColor != null) {
            final key = '${active.gridX + dx},${active.gridY + dy}';
            charMap[key] = char;
            colorMap[key] =
                (active.colors != null && dy < active.colors!.length)
                ? active.colors![dy]
                : active.color;
            bgMap[key] = active.backgroundColor;
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

          if (_gameState.isLevelComplete) {
            if (key == 'm') {
              setState(() {
                _gameState.galabucks += 1000;
              });
              return true;
            }
            return false;
          }
          if (_gameState.isGameOver || _paused) {
            return false;
          }

          if (event.character == ' ') {
            _player.useBomb(_gameState);
            return true;
          }
          if (key == 'r') {
            _gameState.addEntity(
              OmegaLaser(
                x: _player.x + (_player.width ~/ 2).toDouble(),
                y: _player.y,
              ),
            );
            return true;
          }
          return false;
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '--- U P G R A D E S ---',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_levelUpgrades.isNotEmpty) ...[
                                  const SizedBox(width: 2),
                                  GestureDetector(
                                    onTap: _undoUpgrade,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF555500),
                                      ),
                                      child: const Text(' [UNDO] '),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            _buildUpgradeRow(
                              '⚙️ Engines',
                              'Spd: ${12 + _player.speedUpgradeLevel * 2} -> ${14 + _player.speedUpgradeLevel * 2}',
                              100 + (_player.speedUpgradeLevel * 50),
                              () => _buyUpgrade('speed'),
                            ),
                            _buildUpgradeRow(
                              '🔫 Cannons',
                              'Dmg: ${10 + _player.bulletStrengthUpgradeLevel * 5} -> ${15 + _player.bulletStrengthUpgradeLevel * 5}',
                              100 + (_player.bulletStrengthUpgradeLevel * 50),
                              () => _buyUpgrade('bullet'),
                            ),
                            _buildUpgradeRow(
                              '🛡️ Armor',
                              'HP: ${100 + _player.armorUpgradeLevel * 25} -> ${125 + _player.armorUpgradeLevel * 25}',
                              100 + (_player.armorUpgradeLevel * 50),
                              () => _buyUpgrade('armor'),
                            ),
                            _buildUpgradeRow(
                              '🚀 Missiles',
                              _player.homingMissileLevel == 0
                                  ? 'Dmg: 0 -> 20'
                                  : 'Dmg: ${15 + _player.homingMissileLevel * 5} -> ${20 + _player.homingMissileLevel * 5}',
                              _player.homingMissileLevel == 0
                                  ? 1000
                                  : 100 + (_player.homingMissileLevel * 50),
                              () => _buyUpgrade('missile'),
                            ),
                            _buildUpgradeRow(
                              '🔦 Laser',
                              _player.laserBeamLevel == 0
                                  ? 'Dmg: 0 -> 4'
                                  : 'Dmg: ${2 + _player.laserBeamLevel * 2} -> ${4 + _player.laserBeamLevel * 2}',
                              _player.laserBeamLevel == 0
                                  ? 2500
                                  : 100 + (_player.laserBeamLevel * 50),
                              () => _buyUpgrade('laser'),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Vertical Health Bar
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_height, (y) {
                            // Calculate filled segments from bottom to top
                            final double fillRatio =
                                _player.health / _player.maxHealth;
                            final int filledLines = (_height * fillRatio)
                                .ceil();
                            final bool isFilled =
                                (_height - 1 - y) < filledLines;

                            final color = _getHealthColor(fillRatio);

                            return Text(
                              isFilled ? '█' : '░',
                              style: TextStyle(
                                color: isFilled
                                    ? color
                                    : const Color(0xFF333333),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(
                          width: 2,
                        ), // Spacing between health bar and game
                        // Game Grid
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                          ],
                        ),
                        // Vertical Shield Bar
                        const SizedBox(
                          width: 2,
                        ), // Spacing between game and shield bar
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_height, (y) {
                            // Calculate filled segments from bottom to top
                            // Shield technically has no "max", but visually we can scale it to 100 or 150 for the bar
                            final double fillRatio =
                                (_player.shieldHealth / 150.0).clamp(0.0, 1.0);
                            final int filledLines = (_height * fillRatio)
                                .ceil();
                            final bool isFilled =
                                (_height - 1 - y) < filledLines;

                            return Text(
                              isFilled ? '█' : '░',
                              style: TextStyle(
                                color: isFilled
                                    ? const Color(0xFF00E5FF) // Cyan for shield
                                    : const Color(0xFF333333),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Health: ${_player.health}/${_player.maxHealth}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(
                            _player.health / _player.maxHealth.toDouble(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '🏆 Score: ${_gameState.score} | 💰 Galabucks: ${_gameState.galabucks} | 🧨 Bombs: ${_gameState.bombs}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FPS: ${_fps.toStringAsFixed(1)} | Frame: ${_avgFrameTime.toStringAsFixed(2)}ms',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _skipToBoss,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: Color(0xFF440044),
                          ),
                          child: const Text('[ DEBUG: BOSS ]'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Use mouse to move. Space: bomb. P: pause. Q: quit.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  void _buyUpgrade(String type) {
    setState(() {
      if (type == 'speed') {
        int cost = 100 + (_player.speedUpgradeLevel * 50);
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.speedUpgradeLevel++;
          _levelUpgrades.add(type);
        }
      } else if (type == 'bullet') {
        int cost = 100 + (_player.bulletStrengthUpgradeLevel * 50);
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.bulletStrengthUpgradeLevel++;
          _levelUpgrades.add(type);
        }
      } else if (type == 'armor') {
        int cost = 100 + (_player.armorUpgradeLevel * 50);
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.armorUpgradeLevel++;
          _player.health = _player.maxHealth;
          _levelUpgrades.add(type);
        }
      } else if (type == 'missile') {
        int cost = _player.homingMissileLevel == 0
            ? 1000
            : 100 + (_player.homingMissileLevel * 50);
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.homingMissileLevel++;
          _levelUpgrades.add(type);
        }
      } else if (type == 'laser') {
        int cost = _player.laserBeamLevel == 0
            ? 2500
            : 100 + (_player.laserBeamLevel * 50);
        if (_gameState.galabucks >= cost) {
          _gameState.galabucks -= cost;
          _player.laserBeamLevel++;
          _levelUpgrades.add(type);
        }
      }
    });
  }

  void _undoUpgrade() {
    setState(() {
      if (_levelUpgrades.isEmpty) return;
      final type = _levelUpgrades.removeLast();
      if (type == 'speed') {
        _player.speedUpgradeLevel--;
        _gameState.galabucks += 100 + (_player.speedUpgradeLevel * 50);
      } else if (type == 'bullet') {
        _player.bulletStrengthUpgradeLevel--;
        _gameState.galabucks += 100 + (_player.bulletStrengthUpgradeLevel * 50);
      } else if (type == 'armor') {
        _player.armorUpgradeLevel--;
        _gameState.galabucks += 100 + (_player.armorUpgradeLevel * 50);
        if (_player.health > _player.maxHealth) {
          _player.health = _player.maxHealth;
        }
      } else if (type == 'missile') {
        _player.homingMissileLevel--;
        _gameState.galabucks += _player.homingMissileLevel == 0
            ? 1000
            : 100 + (_player.homingMissileLevel * 50);
      } else if (type == 'laser') {
        _player.laserBeamLevel--;
        _gameState.galabucks += _player.laserBeamLevel == 0
            ? 2500
            : 100 + (_player.laserBeamLevel * 50);
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
        SizedBox(width: 20, child: Text(effect)),
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

  void _skipToBoss() {
    setState(() {
      // Find the level right BEFORE the next boss level (multiple of 5 minus 1)
      while ((_levelNumber + 1) % 5 != 0) {
        _levelNumber++;
        _levels.moveNext();
      }
      // Also give some cash for testing
      _gameState.galabucks += 5000;
      
      // Instead of calling _nextLevel directly which bypasses the upgrade
      // screen, we just wipe out the current enemies. The game loop will
      // detect the level is complete and show the upgrade screen.
      // The _nextLevel function will then be called when the user clicks NEXT LEVEL.
      // We must remove all enemies from the current GameState.
      final entitiesToRemove = _gameState.entities.where((e) {
        return e.activeEntities.any((active) => active.isEnemy);
      }).toList();
      for (final e in entitiesToRemove) {
        _gameState.removeEntity(e);
      }
    });
  }
}
