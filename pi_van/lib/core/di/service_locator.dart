import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/sala_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/firebase_sala_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/sala_repository.dart';

class ServiceLocator {
  static final GetIt getIt = GetIt.instance;

  static void setup() {
    // Register FirebaseFirestore
    getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

    // Register FirebaseAuth
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

    // Register Uuid
    getIt.registerLazySingleton<Uuid>(() => const Uuid());

    // Register AuthRemoteDataSource
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(
        firebaseAuth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    );

    // Register FirebaseAuthRepository
    getIt.registerLazySingleton<FirebaseAuthRepository>(
      () => FirebaseAuthRepository(getIt<AuthRemoteDataSource>()),
    );

    // Register SalaRemoteDataSource
    getIt.registerLazySingleton<SalaRemoteDataSource>(
      () => SalaRemoteDataSourceImpl(
        firestore: getIt<FirebaseFirestore>(),
        uuid: getIt<Uuid>(),
      ),
    );

    // Register SalaRepository
    getIt.registerLazySingleton<SalaRepository>(
      () => FirebaseSalaRepository(getIt<SalaRemoteDataSource>()),
    );
  }
}
