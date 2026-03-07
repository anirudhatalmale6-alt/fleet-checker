import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_checker/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FleetCheckerApp());
    expect(find.text('Fleet Checker'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
