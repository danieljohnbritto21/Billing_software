import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/core/database/database_provider.dart';
import 'package:foodbillpro/main.dart';

void main() {
  testWidgets('App root initializes cleanly smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const FoodBillProApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(FoodBillProApp), findsOneWidget);

    await testDb.close();
  });
}
