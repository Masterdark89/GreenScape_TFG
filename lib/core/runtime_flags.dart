import 'runtime_flags_stub.dart'
    if (dart.library.io) 'runtime_flags_io.dart' as runtime_flags;

bool get isFlutterTestRuntime => runtime_flags.isFlutterTestRuntime;
