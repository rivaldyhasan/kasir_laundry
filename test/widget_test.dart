import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kasir_laundry/data/app_store.dart';
import 'package:kasir_laundry/main.dart';

void main() {
  testWidgets('Halaman login tampil', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppStore.instance.load();
    await tester.pumpWidget(const SendShoesApp());
    expect(find.text('Send Shoes Care Kasir'), findsOneWidget);
    expect(find.text('Masuk ke Kasir'), findsOneWidget);
  });
}
