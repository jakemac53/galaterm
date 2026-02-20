import 'dart:io';
import 'package:galaterm/galaterm.dart';
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const GalatermApp());
  await _flushThenExit(0);
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([
    stdout.close(),
    stderr.close(),
  ]).then<void>((_) => exit(status));
}
