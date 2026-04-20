import 'dart:io';

bool get isFlutterTestRuntime => Platform.environment.containsKey('FLUTTER_TEST');
