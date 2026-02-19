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
  Timer? _gameLoop;

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

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        _gameState.tick();
      });
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
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
                        'Score: ${_gameState.score}',
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
