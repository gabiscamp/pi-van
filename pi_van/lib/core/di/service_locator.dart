import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/sala_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/firebase_sala_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/sala_repository.dart';
import '../services/geocoding_service.dart';
import '../services/route_service.dart';
import '../../domain/usecases/route_builder_service.dart';

class ServiceLocator {
  static final GetIt getIt = GetIt.instance;
  static void setup() {
    getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
    getIt.registerLazySingleton<Uuid>(() => const Uuid());
    getIt.registerLazySingleton<GeocodingService>(() => GeocodingService());
    getIt.registerLazySingleton<RouteService>(() => RouteService());
    getIt.registerLazySingleton<RouteBuilderService>(() => RouteBuilderService());

    getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(
      firebaseAuth: getIt<FirebaseAuth>(), firestore: getIt<FirebaseFirestore>(),
    ));
    getIt.registerLazySingleton<SalaRemoteDataSourceImpl>(() => SalaRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(), uuid: getIt<Uuid>(),
    ));
    getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(getIt<AuthRemoteDataSource>()));
    getIt.registerLazySingleton<SalaRepository>(() => FirebaseSalaRepository(getIt<SalaRemoteDataSourceImpl>()));
  }
}
