/// Failures returned by repositories and mapped by providers.
/// Widgets render [message]. They do not open dialogs from the repository.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class RestrictFailure extends AppFailure {
  const RestrictFailure(super.message);
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}
