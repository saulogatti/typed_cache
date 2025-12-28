# Typed Cache

Um pacote Dart de cache **type-safe** com suporte a políticas de retenção (TTL), múltiplos backends de armazenamento e codificação flexível.

## Features

- 🔒 **Type-safe:** Cache com total suporte a tipos genéricos em Dart
- ⏰ **TTL Policies:** Controle de tempo de vida dos itens em cache com política configurável
- 🔌 **Pluggable Backends:** Suporte para múltiplos backends de armazenamento
- 🔄 **Flexible Encoding:** Codecs customizáveis para serialização/desserialização
- 🎯 **Clean Architecture:** Arquitetura modular e desacoplada
- 📝 **Type Entries:** Entrada tipada com metadados e timestamps

## Getting started

### Pré-requisitos

```yaml
environment:
  sdk: ^3.10.4
```

### Instalação

Adicione `typed_cache` ao seu `pubspec.yaml`:

```bash
flutter pub add typed_cache
# ou
dart pub add typed_cache
```

## Usage

### Criando um Cache

```dart
import 'package:typed_cache/typed_cache.dart';

// Criar um cache com TTL de 5 minutos
final cache = TypedCache<String, int>(
  backend: InMemoryBackend(),
  policy: TtlPolicy(duration: Duration(minutes: 5)),
);

// Armazenar um valor
await cache.set('counter', 42);

// Recuperar um valor
final value = await cache.get('counter');
print(value); // 42

// Remover um valor
await cache.remove('counter');

// Limpar todo o cache
await cache.clear();
```

### Usando Diferentes Backends

```dart
// Backend em memória (padrão)
final memoryCache = TypedCache<String, String>(
  backend: InMemoryBackend(),
);

// Backend customizado
final customCache = TypedCache<String, User>(
  backend: MyCustomBackend(),
  codec: JsonCodec<User>(),
);
```

### Políticas de TTL

```dart
// TTL fixo de 1 hora
final ttlPolicy = TtlPolicy(duration: Duration(hours: 1));

// Usar com clock customizado (útil para testes)
final testPolicy = TtlPolicy(
  duration: Duration(minutes: 5),
  clock: FakeClock(),
);
```

## Arquitetura

```
typed_cache/
├── backend.dart       # Interface abstrata para backends
├── cache_store.dart   # Armazenamento interno
├── codec.dart         # Codificação/descodificação
├── entry.dart         # Entrada tipada com metadados
├── errors.dart        # Exceções customizadas
├── typed_cache.dart   # API principal
└── policy/
    ├── clock.dart     # Interface de relógio (para testes)
    └── ttl_policy.dart # Política de TTL
```

## Contribuindo

As contribuições são bem-vindas! Por favor:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/amazing-feature`)
3. Commit suas mudanças (`git commit -m 'Add amazing feature'`)
4. Push para a branch (`git push origin feature/amazing-feature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
