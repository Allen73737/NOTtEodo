import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/widgets/homescreen/aesthetic_homescreen_widgets.dart';
import 'package:notteodo/core/widgets/homescreen/aesthetic_widget_models.dart';

void main() {
  group('Aesthetic Homescreen Widgets Tests', () {
    testWidgets('renders all 8 aesthetic widget types without overflow or errors', (tester) async {
      for (final type in AestheticWidgetType.values) {
        final config = AestheticWidgetConfig(
          id: 'test_${type.name}',
          type: type,
          paperTheme: AestheticPaperTheme.warmCream,
          tapeStyle: WashiTapeStyle.terracotta,
          size: WidgetGridSize.wide,
          showStamp: true,
          stampLabel: 'CURATED',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AestheticHomescreenWidgetCard(config: config),
              ),
            ),
          ),
        );

        expect(find.byType(AestheticHomescreenWidgetCard), findsOneWidget);
        expect(find.byType(WashiTapeStrip), findsOneWidget);
        expect(find.byType(VintagePostalStamp), findsOneWidget);
      }
    });

    testWidgets('respects custom title, subtitle, and hidden stamp', (tester) async {
      const config = AestheticWidgetConfig(
        id: 'test_custom',
        type: AestheticWidgetType.stickyNote,
        paperTheme: AestheticPaperTheme.slateNoir,
        tapeStyle: WashiTapeStyle.vintageGold,
        size: WidgetGridSize.compact,
        showStamp: false,
        customTitle: 'My Custom Note Title',
        customSubtitle: 'Custom poetic excerpt for testing purposes.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AestheticHomescreenWidgetCard(config: config),
            ),
          ),
        ),
      );

      expect(find.text('My Custom Note Title'), findsOneWidget);
      expect(find.text('Custom poetic excerpt for testing purposes.'), findsOneWidget);
      expect(find.byType(VintagePostalStamp), findsNothing);
    });

    test('verifies paper themes and washi tape color values', () {
      for (final theme in AestheticPaperTheme.values) {
        expect(theme.backgroundColor, isNotNull);
        expect(theme.textColor, isNotNull);
        expect(theme.borderColor, isNotNull);
      }

      for (final tape in WashiTapeStyle.values) {
        expect(tape.color, isNotNull);
      }
    });
  });
}
