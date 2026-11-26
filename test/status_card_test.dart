import 'package:bpb/state/app_state.dart';
import 'package:bpb/ui/status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusCard renders', (tester) async {
    final state = AppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: Scaffold(body: StatusCard())),
      ),
    );
    expect(find.byType(StatusCard), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
