# Clean Architecture Guide for Influencer App

## Why Clean Architecture?

Clean architecture helps separate concerns in your app, making it more maintainable, testable, and scalable. For your specific need of using "Firebase as a backend only", clean architecture is the perfect approach.

## Proposed Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── models/
│   ├── user_model.dart
│   ├── message_model.dart
│   ├── campaign_model.dart
│   └── metrics_model.dart
├── services/
│   ├── interfaces/
│   │   ├── auth_service_interface.dart
│   │   ├── user_service_interface.dart
│   │   ├── storage_service_interface.dart
│   │   └── messaging_service_interface.dart
│   ├── firebase/
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── firebase_storage_service.dart
│   └── service_locator.dart
├── repositories/
│   ├── user_repository.dart
│   ├── campaign_repository.dart
│   └── chat_repository.dart
├── screens/
│   ├── login/
│   ├── profile/
│   ├── campaigns/
│   └── messaging/
├── widgets/
└── utils/
```

## Key Components

### 1. Models

Domain models that represent your business data, completely independent of Firebase:

```dart
// models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  // ...
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    // ...
  });
  
  // Factory constructors to convert from data sources
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Convert map to model
  }
  
  Map<String, dynamic> toMap() {
    // Convert model to map
  }
}
```

### 2. Service Interfaces

Define abstract interfaces for services to hide implementation details:

```dart
// services/interfaces/auth_service_interface.dart
abstract class AuthServiceInterface {
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<UserModel?> createAccount(String email, String password);
  Future<void> signOut();
  Stream<UserModel?> authStateChanges();
  // ...
}
```

### 3. Firebase Services

Implement the interfaces with Firebase-specific code:

```dart
// services/firebase/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseAuthService implements AuthServiceInterface {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (e) {
      // Handle errors
      return null;
    }
  }
  
  // Convert Firebase user to your domain model
  UserModel? _userFromFirebase(firebase_auth.User? user) {
    if (user == null) return null;
    
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      // ...
    );
  }
  
  // Other implementations...
}
```

### 4. Repositories

Repositories coordinate with services and provide data to UI:

```dart
// repositories/user_repository.dart
class UserRepository {
  final AuthServiceInterface _authService;
  final UserServiceInterface _userService;
  
  UserRepository(this._authService, this._userService);
  
  Future<UserModel?> signIn(String email, String password) {
    return _authService.signInWithEmail(email, password);
  }
  
  Future<UserModel?> getUserProfile(String userId) {
    return _userService.getUserById(userId);
  }
  
  // Other methods...
}
```

### 5. Service Locator

Register and provide dependencies throughout the app:

```dart
// services/service_locator.dart
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // Register services
  serviceLocator.registerSingleton<AuthServiceInterface>(
    FirebaseAuthService(),
  );
  
  serviceLocator.registerSingleton<UserServiceInterface>(
    FirestoreUserService(),
  );
  
  // Register repositories
  serviceLocator.registerSingleton<UserRepository>(
    UserRepository(
      serviceLocator<AuthServiceInterface>(),
      serviceLocator<UserServiceInterface>(),
    ),
  );
  
  // Other registrations...
}
```

### 6. UI Components

UI components should only depend on repositories or models, never directly on Firebase:

```dart
// screens/login/login_screen.dart
class LoginScreen extends StatelessWidget {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  
  // Use _userRepository instead of FirebaseAuth directly
  Future<void> _login() async {
    try {
      final user = await _userRepository.signIn(email, password);
      if (user != null) {
        // Navigate to home
      }
    } catch (e) {
      // Handle errors
    }
  }
  
  // Build UI...
}
```

## Benefits of This Approach

1. **Separation of Concerns**: Firebase code is isolated in specific service implementations.
2. **Testability**: Easily mock services for testing.
3. **Flexibility**: Can swap Firebase for another backend by implementing new services.
4. **Maintainability**: UI components don't need to know about Firebase details.
5. **Type Safety**: Using your own models instead of Firebase types provides better type safety.

## Migration Strategy

1. Create the models and interfaces first
2. Implement Firebase services that implement these interfaces
3. Create repositories that use these services
4. Update UI components to use repositories instead of Firebase directly
5. Use dependency injection to provide services and repositories

## Recommended Packages

- `get_it` - Simple service locator
- `injectable` - Code generation for dependency injection
- `freezed` - Code generation for immutable models
- `riverpod` or `bloc` - State management that works well with this architecture 