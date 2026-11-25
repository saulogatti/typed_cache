// coverage:ignore-file
/// The failure variant of [Result].
///
/// `F` is the type exposed by [error].
final class Failure<S, F> extends Result<S, F> {
  /// Creates a failure containing [error].
  const Failure(this.error);

  /// The contained failure value.
  final F error;
}

/// A value that is either a success of type `S` or a failure of type `F`.
///
/// Exhaustive pattern matching can distinguish [Success] and [Failure].
sealed class Result<S, F> {
  /// Creates an empty base result.
  const Result();

  /// Creates a failure result.
  factory Result.failure(F failure) = Failure<S, F>;

  /// Creates a success result.
  factory Result.success(S value) = Success<S, F>;

  /// Returns the error, or `null` for a success.
  F? get failureOrNull => isFailure ? (this as Failure<S, F>).error : null;

  /// Returns the success value, or `null` for a failure.
  S? get getOrNull => isSuccess ? (this as Success<S, F>).value : null;

  /// Whether this result contains a failure.
  bool get isFailure => this is Failure<S, F>;

  /// Whether this result contains a success value.
  bool get isSuccess => this is Success<S, F>;

  /// Applies the callback matching this result.
  T fold<T extends Object?>({
    required T Function(S value) onSuccess,
    required T Function(F error) onFailure,
  }) => switch (this) {
    Success<S, F>(value: final S v) => onSuccess(v),
    Failure<S, F>(error: final F e) => onFailure(e),
  };

  /// Invokes one callback according to this result.
  ///
  /// Prefer [fold] in new code when a nullable return type may be required.
  T when<T extends Object>(T Function(S value) onSuccess, T Function(F error) onFailure) =>
      fold<T>(onSuccess: onSuccess, onFailure: onFailure);

  /// Runs [block], converting thrown values to [Exception] failures.
  static Future<Result<T, Exception>> guard<T extends Object>(Future<T> Function() block) async {
    try {
      return Result<T, Exception>.success(await block());
    } on Exception catch (e) {
      return Result<T, Exception>.failure(e);
    } on Object catch (e) {
      return Result<T, Exception>.failure(Exception(e.toString()));
    }
  }

  /// Runs [action], returning exceptions of type `F` as failures.
  ///
  /// Other thrown values propagate.
  ///
  /// ```dart
  /// final result = await Result.resultAsync<MyType, MyException>(() async {
  ///   return fetchData();
  /// });
  /// ```
  static Future<Result<T, F>> resultAsync<T, F extends Object>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Result<T, F>.success(value);
    } on F catch (e) {
      return Result<T, F>.failure(e);
    }
  }
}

/// The success variant of [Result].
///
/// `S` is the type exposed by [value].
final class Success<S, F> extends Result<S, F> {
  /// Creates a success containing [value].
  const Success(this.value);

  /// The contained success value.
  final S value;
}

/// Transformations and side effects for [Result].
extension ResultExtension<S, F> on Result<S, F> {
  /// Flat maps a [Result] to a new [Result] with a different success type.
  Result<R, F> flatMap<R extends Object>(Result<R, F> Function(S value) mapper) =>
      fold<Result<R, F>>(onSuccess: mapper, onFailure: Result<R, F>.failure);

  /// Flat maps a [Result] to a new [Result] with a different error type.
  Result<S, R> flatMapError<R>(Result<S, R> Function(F error) mapper) =>
      fold(onSuccess: Result<S, R>.success, onFailure: (error) => mapper(error));

  /// Maps a [Result] to a new [Result] with a different success type.
  Result<R, F> map<R extends Object>(R Function(S value) mapper) => fold(
    onSuccess: (value) => Result<R, F>.success(mapper(value)),
    onFailure: Result<R, F>.failure,
  );

  /// Maps a [Result] to a new [Result] with a different error type.
  Result<S, R> mapError<R>(R Function(F error) mapper) => fold(
    onSuccess: Result<S, R>.success,
    onFailure: (error) => Result<S, R>.failure(mapper(error)),
  );

  /// Executes a side effect function if the result is a failure.
  Result<S, F> onFailure(void Function(F error) effect) {
    if (this case Failure<S, F>(error: final F e)) {
      effect(e);
    }
    return this;
  }

  /// Executes a side effect function if the result is a success.
  Result<S, F> onSuccess(void Function(S value) effect) {
    if (this case Success<S, F>(value: final S v)) {
      effect(v);
    }
    return this;
  }
}
