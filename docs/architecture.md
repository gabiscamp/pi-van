# Arquitetura — VanGo

## Visão geral

Clean Architecture com MVVM na camada de apresentação.

```
pi_van/lib/
├── core/
│   ├── di/                  → service_locator.dart (GetIt)
│   ├── routing/             → app_router.dart, active_route_args.dart
│   ├── services/            → route_service.dart, geocoding_service.dart,
│   │                           notification_service.dart, external_nav_service.dart,
│   │                           fcm_service.dart (reservado)
│   ├── utils/               → validators.dart
│   └── via_cep_service.dart → busca CEP
│
├── domain/
│   ├── entities/            → User, Sala, Faculdade, RouteStopEntity,
│   │                           StudentAddress, Attendance, AddressRef
│   ├── enums/               → Role, AttendanceStatus, RouteType,
│   │                           StopStatus, RouteStopKind
│   ├── repositories/        → AuthRepository (interface)
│   │                           SalaRepository (interface)
│   └── usecases/            → LoginUseCase, RegisterUseCase,
│                               CreateSalaUseCase, JoinSalaUseCase,
│                               RouteBuilderService
│
├── data/
│   ├── datasources/         → AuthRemoteDataSource, SalaRemoteDataSourceImpl
│   ├── models/              → UserModel, SalaModel, FaculdadeModel,
│   │                           StudentAddressModel
│   └── repositories/        → FirebaseAuthRepository, FirebaseSalaRepository
│
└── presentation/
    ├── pages/
    │   ├── shared/          → SplashPage, LandingPage, LoginPage,
    │   │                       RegisterPage, ProfilePage
    │   ├── driver/          → DriverShell, DriverDashboardTab,
    │   │                       DriverRouteTab, DriverStudentsTab,
    │   │                       DriverProfileTab, ManageSalasPage,
    │   │                       ManageFaculdadesPage, CreateSalaPage,
    │   │                       AttendanceOverviewPage, RouteBuilderPage,
    │   │                       ActiveRoutePage
    │   └── student/         → StudentShell, StudentHomeTab, StudentMapTab,
    │                           StudentProfileTab, JoinSalaPage,
    │                           ManageAddressesPage, SelectFaculdadePage
    ├── theme/               → app_theme.dart
    ├── viewmodels/          → AuthViewModel
    └── widgets/             → AppTextField, AppButton, StatCard,
                               SectionHeader, StatusBadge, AppScaffold
```

---

## Camadas

### Domain
- Regras de negócio puras — sem dependências externas
- Entities são imutáveis (Dart `const`)
- Repository interfaces definem contratos sem implementação

### Data
- Implementa os repositórios usando Firebase
- `AuthRemoteDataSource` → Firebase Auth + Firestore
- `SalaRemoteDataSourceImpl` → Firestore (salas, faculdades, attendance, driverLocation)
- Models fazem `fromMap()`/`toMap()` para serialização

### Presentation (MVVM)
- `AuthViewModel` (ChangeNotifier) é a única ViewModel — coordena login, cadastro, seleção de sala
- Pages lêem estado do ViewModel e do Firestore (streams diretos)
- `AppRouter.authViewModel` é singleton global acessível de qualquer página

---

## Serviços externos

| Serviço | Uso | Custo |
|---|---|---|
| **OSRM** (`router.project-osrm.org`) | Cálculo de rota e otimização TSP | Gratuito |
| **Nominatim** (`nominatim.openstreetmap.org`) | Geocoding endereço → lat/lng | Gratuito |
| **ViaCEP** (`viacep.com.br`) | Busca endereço por CEP | Gratuito |
| **OpenStreetMap** (tile.openstreetmap.org) | Tiles do mapa no flutter_map | Gratuito |
| **Firebase Auth** | Autenticação | Gratuito (Spark) |
| **Cloud Firestore** | Banco de dados em tempo real | Gratuito (50k leituras/dia) |
| **Firebase Hosting** | PWA / Web app | Gratuito |

---

## Fluxo de dados — rota de volta em tempo real

```
Aluno toca "Estou liberado"
        ↓
saveVote() → Firestore: salas/{salaId}/attendance/{date}/votes/{userId}
        ↓
attendanceStream() no ActiveRoutePage (motorista) detecta mudança
        ↓
_onAttendanceUpdate() → NotificationService.showLiberado() [voz + banner]
        ↓
_addStudentToRoute() → adiciona paradas à lista _stops
        ↓
_calculateRoute() → OSRM recalcula polyline + steps
        ↓
setState() → mapa e banner de instrução se atualizam
        ↓
Snackbar com botão "Navegar" → ExternalNavService.openGoogleMapsWithRoute()
```

---

## Dependência de injeção (GetIt)

```dart
// service_locator.dart
getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(...))
getIt.registerLazySingleton<SalaRepository>(() => FirebaseSalaRepository(...))
getIt.registerLazySingleton<RouteService>(() => RouteService())
getIt.registerLazySingleton<RouteBuilderService>(() => RouteBuilderService())
getIt.registerLazySingleton<GeocodingService>(() => GeocodingService())
```
