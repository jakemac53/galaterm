import 'package:nocterm/nocterm.dart';

class GalatermApp extends StatefulComponent {
  const GalatermApp({super.key});

  @override
  State<GalatermApp> createState() => _GalatermAppState();
}

class _GalatermAppState extends State<GalatermApp> {
  @override
  Component build(BuildContext context) {
    return NoctermApp(
      title: 'Galaterm',
      child: Focusable(
        focused: true,
        onKeyEvent: (event) {
          if (event.character?.toLowerCase() == 'q') {
            shutdownApp();
            return true;
          }
          return false;
        },
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Welcome to Galaterm!'),
                  SizedBox(height: 1),
                  Text(
                    'Press "q" to quit.',
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
