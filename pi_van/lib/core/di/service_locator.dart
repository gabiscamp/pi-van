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

class ServiceLocator {
  static final GetIt getIt = GetIt.instance;

  static void setup() {
    // Firebase instances
    getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
    getIt.registerLazySingleton<Uuid>(() => const Uuid());

    // Data sources
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(
        firebaseAuth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    );
    getIt.registerLazySingleton<SalaRemoteDataSource>(
      () => SalaRemoteDataSourceImpl(
        firestore: getIt<FirebaseFirestore>(),
        uuid: getIt<Uuid>(),
      ),
    );

    // Repositories - registrar como interface para injeção limpa
    getIt.registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(getIt<AuthRemoteDataSource>()),
    );
    getIt.registerLazySingleton<SalaRepository>(
      () => FirebaseSalaRepository(getIt<SalaRemoteDataSource>()),
    );
  }
}
