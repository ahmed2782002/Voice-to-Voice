import 'package:flutter_test/flutter_test.dart';

extension WaitFor on WidgetTester {
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(step);
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out after $timeout waiting for $finder');
  }

  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(step);
      if (finder.evaluate().isEmpty) return;
    }
    throw TestFailure(
      'Timed out after $timeout waiting for $finder to disappear',
    );
  }

  Future<void> tapVisible(Finder finder) async {
    await ensureVisible(finder);
    await pump();
    await tap(finder);
    await pump();
  }
}
