import 'package:flutter_ci_quality_template/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('boots into the tasks screen with seeded data', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Review pull request'), findsOneWidget);
    expect(find.text('Cut the release'), findsOneWidget);
  });
}
