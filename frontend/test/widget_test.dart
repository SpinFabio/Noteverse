import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noteverse/main.dart';

void main() {
  testWidgets('Mostra la schermata iniziale', (tester) async {
    await tester.pumpWidget(const NoteverseApp());
    expect(find.text('Noteverse'), findsOneWidget);
    expect(find.text('Verifica connessione'), findsOneWidget);
    expect(find.text('Test backend'), findsOneWidget);
  });

  testWidgets('Displays the backend greeting', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/hello');
      return http.Response('{"message":"Hello from Noteverse!"}', 200);
    });
    await tester.pumpWidget(NoteverseApp(client: client));
    await tester.tap(find.text('Test backend'));
    await tester.pumpAndSettle();
    expect(find.text('Hello from Noteverse!'), findsOneWidget);
  });

  testWidgets('Displays errors and allows retrying', (tester) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) throw http.ClientException('Offline');
      return http.Response('{"message":"Hello from Noteverse!"}', 200);
    });
    await tester.pumpWidget(NoteverseApp(client: client));
    await tester.tap(find.text('Test backend'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Test fallito:'), findsOneWidget);
    await tester.tap(find.text('Test backend'));
    await tester.pumpAndSettle();
    expect(find.text('Hello from Noteverse!'), findsOneWidget);
  });
}
