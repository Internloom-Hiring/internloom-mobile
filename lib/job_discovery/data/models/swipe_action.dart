enum SwipeDirection {
  left,
  up,
  right,
}

class PersistenceResult {
  const PersistenceResult({required this.created});

  /// False means the database already contained the equivalent state.
  /// This is important for safe undo: an existing application must never
  /// be deleted just because a duplicate right swipe occurred.
  final bool created;
}
