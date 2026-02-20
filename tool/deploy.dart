import 'dart:io';

void main() async {
  print('Compiling web/main.dart...');
  final compileResult = await Process.run('dart', [
    'compile',
    'js',
    '-O2',
    '--no-source-maps',
    '-o',
    'web/main.dart.js',
    'web/main.dart',
  ]);
  
  if (compileResult.exitCode != 0) {
    print('Compilation failed:');
    print(compileResult.stdout);
    print(compileResult.stderr);
    exit(1);
  }
  print('Compilation successful.');
  
  final depsFile = File('web/main.dart.js.deps');
  if (await depsFile.exists()) {
    await depsFile.delete();
  }

  final targetDir = Directory('../jakemac53.github.io/galaterm');
  if (!await targetDir.exists()) {
    print('Error: Target directory ${targetDir.path} does not exist.');
    exit(1);
  }

  final sourceFile = File('web/main.dart.js');
  final targetFile = File('${targetDir.path}/main.dart.js');
  
  await sourceFile.copy(targetFile.path);
  print('Copied main.dart.js to ${targetFile.path}');
  
  stdout.write('Deploy to GitHub Pages? (y/N): ');
  final input = stdin.readLineSync();
  if (input?.toLowerCase() == 'y') {
    print('Deploying...');
    
    final addResult = await Process.run('git', ['add', '.'], workingDirectory: '../jakemac53.github.io/');
    if (addResult.exitCode != 0) {
      print('git add failed: ${addResult.stderr}');
      exit(1);
    }
    
    final commitResult = await Process.run('git', ['commit', '-m', 'deploy'], workingDirectory: '../jakemac53.github.io/');
    if (commitResult.exitCode != 0 && !commitResult.stdout.toString().contains('nothing to commit')) {
      print('git commit failed: ${commitResult.stderr}');
      print(commitResult.stdout);
      // We don't exit here, might just be nothing to commit, so we can still try to push.
    }
    
    final pushResult = await Process.run('git', [
      'push',
      'origin',
      'master',
    ], workingDirectory: '../jakemac53.github.io/');
    if (pushResult.exitCode != 0) {
      print('git push failed: ${pushResult.stderr}');
      exit(1);
    }
    
    print('Successfully deployed!');
  } else {
    print('Deployment aborted.');
  }
}
