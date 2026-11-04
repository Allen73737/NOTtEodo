import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../enterprise/sanctuary_logger.dart';
import 'aesthetic_homescreen_widgets.dart';
import 'aesthetic_widget_models.dart';

/// Service managing device homescreen widgets for NOTtEodo.
class HomescreenWidgetService {
  static final HomescreenWidgetService _instance = HomescreenWidgetService._internal();
  factory HomescreenWidgetService() => _instance;
  HomescreenWidgetService._internal();

  static const String androidWidgetProvider = 'NotteodoWidgetProvider';
  static const String appGroupId = 'group.com.notteodo.notteodo';

  bool _initialized = false;

  /// Initializes home_widget channel with AppGroup ID.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _initialized = true;
      SanctuaryLogger().info('HomescreenWidget', 'Initialized HomeWidget service');
    } catch (e) {
      SanctuaryLogger().warn('HomescreenWidget', 'HomeWidget init skipped: $e');
    }
  }

  /// Renders a Flutter widget directly into an image and updates the Android/iOS home widget.
  Future<String?> renderAndSyncWidget(AestheticWidgetConfig config) async {
    if (kIsWeb) return null;

    try {
      await initialize();

      // Render pixel-perfect widget bitmap
      final widgetTree = AestheticHomescreenWidgetCard(config: config);
      final filename = 'notteodo_widget_${config.type.name}';

      final imagePath = await HomeWidget.renderFlutterWidget(
        widgetTree,
        key: 'notteodo_widget_image',
        logicalSize: Size(config.size.width, config.size.height),
        pixelRatio: 3.0,
      );

      // Save widget configuration keys
      await HomeWidget.saveWidgetData<String>('widget_type', config.type.name);
      await HomeWidget.saveWidgetData<String>('widget_title', config.customTitle ?? config.type.displayName);
      await HomeWidget.saveWidgetData<String>('notteodo_widget_image', imagePath);

      // Request home widget update
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          name: androidWidgetProvider,
          androidName: androidWidgetProvider,
        );
      }

      SanctuaryLogger().info('HomescreenWidget', 'Rendered widget to $imagePath');
      return imagePath;
    } catch (e) {
      SanctuaryLogger().error('HomescreenWidget', 'Failed to render home widget: $e');
      return null;
    }
  }

  /// Requests the OS to pin the widget directly to the user's home screen.
  Future<bool> requestPinWidget(AestheticWidgetConfig config) async {
    if (kIsWeb) return false;

    try {
      // First ensure the latest visual is rendered
      await renderAndSyncWidget(config);

      if (Platform.isAndroid) {
        final success = await HomeWidget.requestPinWidget(
          androidName: androidWidgetProvider,
        );
        return success ?? false;
      }
      return false;
    } catch (e) {
      SanctuaryLogger().warn('HomescreenWidget', 'requestPinWidget not supported or failed: $e');
      return false;
    }
  }
}
