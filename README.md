# Typed Cache

A **type-safe** Dart caching package with support for retention policies (TTL), multiple storage backends, and flexible encoding.

## Features

- 🔒 **Type-safe:** Fully type-safe cache with generic type support in Dart
- ⏰ **TTL Policies:** Cache item lifetime control with configurable policies
- 🔌 **Pluggable Backends:** Support for multiple storage backends
- 🔄 **Flexible Encoding:** Customizable codecs for serialization/deserialization
- 🎯 **Clean Architecture:** Modular and decoupled architecture
- 📝 **Type Entries:** Typed entries with metadata and timestamps

## Getting started

### Prerequisites

```yaml
environment:
  sdk: ^3.10.4
```

### Installation

Add `typed_cache` to your `pubspec.yaml`:

```bash
flutter pub add typed_cache
# or
dart pub add typed_cache
```

## Usage

### Creating a Cache

```dart
import 'package:typed_cache/typed_cache.dart';

// Create a cache with 5 minutes TTL
final cache = TypedCache<String, int>(
  backend: InMemoryBackend(),
  policy: TtlPolicy(duration: Duration(minutes: 5)),
);

// Store a value
await cache.set('counter', 42);

// Retrieve a value
final value = await cache.get('counter');
print(value); // 42

// Remove a value
await cache.remove('counter');

// Clear the entire cache
await cache.clear();
```

### Using Different Backends

```dart
// In-memory backend (default)
final memoryCache = TypedCache<String, String>(
  backend: InMemoryBackend(),
);

// Custom backend
final customCache = TypedCache<String, User>(
  backend: MyCustomBackend(),
  codec: JsonCodec<User>(),
);
```

### TTL Policies

```dart
// Fixed TTL of 1 hour
final ttlPolicy = TtlPolicy(duration: Duration(hours: 1));

// Custom clock (useful for testing)
final testPolicy = TtlPolicy(
  duration: Duration(minutes: 5),
  clock: FakeClock(),
);
```

## Architecture

```
typed_cache/
├── backend.dart       # Abstract interface for backends
├── cache_store.dart   # Internal storage
├── codec.dart         # Encoding/decoding
├── entry.dart         # Typed entry with metadata
├── errors.dart        # Custom exceptions
├── typed_cache.dart   # Main API
└── policy/
    ├── clock.dart     # Clock interface (for testing)
    └── ttl_policy.dart # TTL policy
```

## Contributing

Contributions are welcome! Please:

1.  Fork the repository
2. Create a branch for your feature (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
