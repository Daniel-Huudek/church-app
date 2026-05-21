import 'package:flutter_test/flutter_test.dart';
import 'package:church_app_mobile/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('IPI Avaré'), findsWidgets);
  });
}
