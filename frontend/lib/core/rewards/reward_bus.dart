import 'dart:async';

/// Something the user did by hand that counts toward today's goal.
enum RewardAction { note, task, taskDone, event, habit, habitDone, journal, expense, trip, outfit, pin, shopping }

/// Carries [RewardAction]s from the state notifiers to the rewards host in the shell.
///
/// Notifiers emit when an item is created or completed. Work the assistant does on
/// the user's behalf runs inside [quietly], so only hands-on actions earn rewards.
abstract final class RewardBus {
  static final StreamController<RewardAction> _controller = StreamController<RewardAction>.broadcast();
  static int _muted = 0;

  static Stream<RewardAction> get stream => _controller.stream;

  static void emit(RewardAction action) {
    if (_muted == 0) _controller.add(action);
  }

  /// Runs [body] without emitting anything (assistant actions, imports, restores).
  static T quietly<T>(T Function() body) {
    _muted++;
    try {
      return body();
    } finally {
      _muted--;
    }
  }
}
