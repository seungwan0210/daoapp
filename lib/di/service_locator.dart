import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Auth
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';

// Point & Ranking
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/repositories/point_record_repository_impl.dart';

// Arena
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/data/repositories/arena_repository_impl.dart';

// Storage
import 'package:daoapp/services/storage_service.dart';

// Training
import 'package:daoapp/data/repositories/training_repository.dart';
import 'package:daoapp/data/repositories/training_repository_impl.dart';
import 'package:daoapp/data/repositories/training_progress_repository.dart';
import 'package:daoapp/data/repositories/training_progress_repository_impl.dart';

// Grip Baseline
import 'package:daoapp/data/repositories/grip_baseline_repository.dart';
import 'package:daoapp/data/repositories/grip_baseline_repository_impl.dart';

// Chat
import 'package:daoapp/data/repositories/chat_repository.dart';
import 'package:daoapp/data/repositories/chat_repository_impl.dart';

// MyLog
import 'package:daoapp/data/repositories/my_log_repository.dart';

// ✅ Practice [NEW]
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/data/repositories/practice_repository_impl.dart';

// Google Calendar Service
import 'package:daoapp/core/services/google_calendar_service.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // === Firebase 인스턴스 ===
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // === Auth ===
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    firebaseAuth: sl<FirebaseAuth>(),
    googleSignIn: sl<GoogleSignIn>(),
  ));

  // === MyLog Repository ===
  // PracticeRepository에서 의존하므로 상단에 배치합니다.
  sl.registerLazySingleton<MyLogRepository>(() => MyLogRepository());

  // ✅ [수정됨] Practice Repository 등록 (세미콜론 추가 및 의존성 주입)
  sl.registerLazySingleton<PracticeRepository>(
        () => PracticeRepositoryImpl(myLogRepository: sl<MyLogRepository>()),
  );

  // === Point & Ranking ===
  sl.registerLazySingleton<PointRecordRepository>(() => PointRecordRepositoryImpl());

  // ✅ 라이브 채팅 Repository 등록
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(firestore: sl<FirebaseFirestore>()));

  // === Arena ===
  sl.registerLazySingleton<ArenaRepository>(() => ArenaRepositoryImpl());

  // === Storage ===
  sl.registerLazySingleton<StorageService>(() => StorageService());

  // === Training Session Repository 등록 ===
  sl.registerLazySingleton<TrainingRepository>(() => TrainingRepositoryImpl(firestore: sl<FirebaseFirestore>()));

  // === Training Progress Repository 등록 ===
  sl.registerLazySingleton<TrainingProgressRepository>(() => TrainingProgressRepositoryImpl(firestore: sl<FirebaseFirestore>()));

  // ✅ Grip Baseline Repository 등록
  sl.registerLazySingleton<GripBaselineRepository>(() => GripBaselineRepositoryImpl(
    auth: sl<FirebaseAuth>(),
    firestore: sl<FirebaseFirestore>(),
    storage: sl<FirebaseStorage>(),
  ));

  // ✅ [NEW] Google Calendar Service 등록
  sl.registerLazySingleton<GoogleCalendarService>(() => GoogleCalendarService());
}