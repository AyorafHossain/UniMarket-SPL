import 'package:flutter/material.dart'; // Just to trick analyzer
import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // Replace withOpacity(x) with withValues(alpha: x)
    final opacityRegex = RegExp(r'\.withOpacity\(([^)]+)\)');
    if (opacityRegex.hasMatch(content)) {
      content = content.replaceAllMapped(opacityRegex, (match) {
        return '.withValues(alpha: ${match.group(1)})';
      });
      modified = true;
    }

    // Replace colorScheme.background with colorScheme.surface
    final bgRegex = RegExp(r'\.background');
    if (bgRegex.hasMatch(content)) {
      content = content.replaceAllMapped(bgRegex, (match) {
        return '.surface';
      });
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
