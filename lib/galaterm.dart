import 'dart:async';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
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
    _player = Player(x: _width ~/ 2, y: _height - 2);
    _gameState.addEntity(_player);
    _gameState.addEntity(EnemyFormation(rows: 4, cols: 10));
    // Initialize the entities immediately so they render on frame 1
    _gameState.tick();

    _gameLoop = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    final entityMap = <String, Entity>{};
    for (final e in _gameState.entities) {
      for (final active in e.activeEntities) {
        if (active.health > 0) {
          entityMap['${active.x},${active.y}'] = active;
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
                        final entity = entityMap['$x,$y'];
                        return MouseRegion(
                          onHover: (event) {
                            if (_player.x != x || _player.y != y) {
                              _player.moveTo(x, y);
                              // We don't need a hard setState here instantly since the game loop
                              // re-renders every 100ms anyway, but for ultra responsiveness:
                              setState(() {});
                            }
                          },
                          onEnter: (event) {
                            if (_player.x != x || _player.y != y) {
                              _player.moveTo(x, y);
                              setState(() {});
                            }
                          },
                          child: Text(
                            entity?.character ?? ' ',
                            style: TextStyle(color: entity?.color),
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
