# UML (draft)

```mermaid
classDiagram
  class User {
    +String id
    +String name
    +String email
    +Role role
    +String? salaId
  }

  class Sala {
    +String id
    +String name
    +String accessCode
    +String driverId
  }

  class LoginUseCase {
    -AuthRepository repository
    +execute(email, password) User
  }

  class RegisterUseCase {
    -AuthRepository repository
    +execute(name, email, password, role) User
  }

  class JoinSalaUseCase {
    -SalaRepository repository
    +execute(studentId, accessCode) bool
  }

  class CreateSalaUseCase {
    -SalaRepository repository
    +execute(name, driverId) Sala
  }

  class AuthRepository {
    <<interface>>
    +login(email, password) User
    +register(name, email, password, role) User
    +logout() void
  }

  class SalaRepository {
    <<interface>>
    +createSala(name, driverId) Sala
    +joinSala(studentId, accessCode) bool
    +getSalaById(salaId) Sala?
  }

  class FirebaseAuthRepository {
    -AuthRemoteDataSource remote
  }

  class FirebaseSalaRepository {
    -SalaRemoteDataSource remote
  }

  class Role {
    <<enumeration>>
    MOTORISTA
    ESTUDANTE
  }

  User --> Role
  User --> Sala : belongsTo

  LoginUseCase --> AuthRepository : uses
  RegisterUseCase --> AuthRepository : uses
  JoinSalaUseCase --> SalaRepository : uses
  CreateSalaUseCase --> SalaRepository : uses

  FirebaseAuthRepository ..|> AuthRepository
  FirebaseSalaRepository ..|> SalaRepository
```

Notes:
- The repositories are interfaces in the domain layer.
- Firebase implementations live in the data layer and depend on data sources.
- Presentation (MVVM) consumes use cases via view models.
