import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_queue_api/trail_queue_api.dart';

import 'package:trail_queue/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(pathChannel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.';
      }
      return null;
    });

    const connectivityChannel =
        MethodChannel('dev.fluttercommunity.plus/connectivity');
    messenger.setMockMethodCallHandler(connectivityChannel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi'];
      }
      return null;
    });

    const connectivityStatusChannel =
        EventChannel('dev.fluttercommunity.plus/connectivity_status');
    messenger.setMockStreamHandler(
      connectivityStatusChannel,
      _ConnectivityMockStreamHandler(),
    );

    await AppServices.instance.init();
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('TRAIL QUEUE'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}

class _ConnectivityMockStreamHandler extends MockStreamHandler {
  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    events.success(['wifi']);
  }

  @override
  void onCancel(dynamic arguments) {}
}
