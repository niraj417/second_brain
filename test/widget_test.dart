import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:second_brain_tws_app/main.dart';
import 'package:second_brain_tws_app/services/co_pilot_service.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CoPilotService(),
        child: const SecondBrainApp(),
      ),
    );

    // Verify dashboard title is shown
    expect(find.text('SECOND BRAIN'), findsOneWidget);
  });
}
