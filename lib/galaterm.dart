import 'dart:async';
import 'package:nocterm/nocterm.dart';

import 'enemy_formation.dart';
import 'game_state.dart';
import 'player.dart';

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

  final int _width = 80;
  final int _height = 40;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(width: _width, height: _height);
    _player = Player(x: (_width ~/ 2).toDouble(), y: (_height - 2).toDouble());
    _gameState.addEntity(_player);
    _gameState.addEntity(EnemyFormation(rows: 3, cols: 8));
    // Initialize the entities immediately so they render on frame 1
    _gameState.tick();

    _runGameLoop();
  }

  Future<void> _runGameLoop() async {
    final sw = Stopwatch();
    while (_running) {
      sw.reset();
      sw.start();

      if (!mounted) break;

      setState(() {
        _gameState.tick();
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
          if (event.character?.toLowerCase() == 'q') {
            shutdownApp();
            return true;
          }
          if (event.logicalKey == LogicalKey.space || event.character == ' ') {
            _player.fire(_gameState);
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
                            if (_player.x != targetX || _player.y != targetY) {
                              _player.moveTo(targetX, targetY);
                              setState(() {});
                            }
                          },
                          onEnter: (event) {
                            final targetX = (x - (_player.width ~/ 2))
                                .toDouble();
                            final targetY = (y - (_player.height ~/ 2))
                                .toDouble();
                            if (_player.x != targetX || _player.y != targetY) {
                              _player.moveTo(targetX, targetY);
                              setState(() {});
                            }
                          },
                          child: Text(
                            charMap['$x,$y'] ?? ' ',
                            style: TextStyle(color: colorMap['$x,$y']),
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
                          value: (_player.health / 100.0).clamp(0.0, 1.0),
                          valueColor: _player.health > 20
                              ? const Color(0xFF00FF00)
                              : const Color(0xFFFF0000),
                          backgroundColor: const Color(0xFF333333),
                          showPercentage: false,
                          label: 'Health: ${_player.health}',
                        ),
                      ),
                      Text(
                        'Score: ${_gameState.score} | FPS: ${_fps.toStringAsFixed(1)} | Frame: ${_avgFrameTime.toStringAsFixed(2)}ms',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Use mouse to move. Press SPACE to fire. Press "q" to quit.',
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
}
