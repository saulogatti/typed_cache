final class Failure<S, F> extends Result<S, F> {
  final F error;
  const Failure(this.error);
}

/// A lightweight implementation of the Result pattern for Clean Architecture.
/// Uses Dart 3 sealed classes to ensure exhaustive handling.
///
/// [S] is the success type [Success.value].
/// [F] is the failure type [Failure.error].
sealed class Result<S, F> {
  const Result();

  /// Creates a Failure result
  factory Result.failure(F failure) = Failure<S, F>;

  /// Creates a Success result
  factory Result.success(S value) = Success<S, F>;

  /// Returns the error or null if success
  F? get failureOrNull => isFailure ? (this as Failure<S, F>).error : null;

  /// Returns the success value or null if failure
  S? get getOrNull => isSuccess ? (this as Success<S, F>).value : null;

  /// Checks if this is a failure
  bool get isFailure => this is Failure<S, F>;

  /// Checks if this is a success
  bool get isSuccess => this is Success<S, F>;

  /// The magic method: forces handling of both cases.
  /// Ideal for use in Widgets/Blocs.
  T fold<T extends Object?>({
    required T Function(S value) onSuccess,
    required T Function(F error) onFailure,
  }) {
    return switch (this) {
      Success<S, F>(value: final S v) => onSuccess(v),
      Failure<S, F>(error: final F e) => onFailure(e),
    };
  }

  /// Semantic alias for [fold], maintained for readability and familiarity
  /// with pattern matching APIs (e.g., `when` in other languages).
  /// Especially useful in Widgets/Blocs; for new code, prefer using [fold].
  T when<T extends Object>(
    T Function(S value) onSuccess,
    T Function(F error) onFailure,
  ) => fold<T>(onSuccess: onSuccess, onFailure: onFailure);

  /// Static utility to wrap dangerous calls (try-catch)
  static Future<Result<T, Exception>> guard<T extends Object>(
    Future<T> Function() block,
  ) async {
    try {
      return Result<T, Exception>.success(await block());
    } on Exception catch (e) {
      return Result<T, Exception>.failure(e);
    } catch (e) {
      return Result<T, Exception>.failure(Exception(e.toString()));
    }
  }

  /// Asynchronous utility to create a Result from an async function
  /// that may throw an exception of type F.
  /// Type F must extend Object to ensure it is not null.
  /// Usage example:
  /// ```dart
  /// final result = await Result.resultAsync<MyType, MyException>(() async {
  ///    // code that may throw MyException
  ///  return await fetchData();
  /// });
  /// ```
  static Future<Result<T, F>> resultAsync<T, F extends Object>(
    Future<T> Function() action,
  ) async {
    try {
      final T value = await action();
      return Result<T, F>.success(value);
    } on F catch (e) {
      return Result<T, F>.failure(e);
    }
  }
}

final class Success<S, F> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

extension ResultExtension<S, F> on Result<S, F> {
  /// Flat maps a [Result] to a new [Result] with a different success type.
  Result<R, F> flatMap<R extends Object>(
    Result<R, F> Function(S value) mapper,
  ) {
    return fold<Result<R, F>>(
      onSuccess: mapper,
      onFailure: (F error) => Result<R, F>.failure(error),
    );
  }

  /// Flat maps a [Result] to a new [Result] with a different error type.
  Result<S, R> flatMapError<R>(Result<S, R> Function(F error) mapper) {
    return fold(
      onSuccess: (S value) => Result<S, R>.success(value),
      onFailure: (F error) => mapper(error),
    );
  }

  /// Maps a [Result] to a new [Result] with a different success type.
  Result<R, F> map<R extends Object>(R Function(S value) mapper) {
    return fold(
      onSuccess: (S value) => Result<R, F>.success(mapper(value)),
      onFailure: (F error) => Result<R, F>.failure(error),
    );
  }

  /// Maps a [Result] to a new [Result] with a different error type.
  Result<S, R> mapError<R>(R Function(F error) mapper) {
    return fold(
      onSuccess: (S value) => Result<S, R>.success(value),
      onFailure: (F error) => Result<S, R>.failure(mapper(error)),
    );
  }

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
