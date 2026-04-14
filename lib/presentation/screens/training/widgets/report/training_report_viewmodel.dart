// lib/presentation/screens/training/widgets/report/training_report_viewmodel.dart

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/data/models/training_report_model.dart';

/// 🔹 오버레이(UI)에서 쓰기 좋은 형태로 묶어놓은 ViewModel
///
/// - currentSession: 방금 끝난 세션
/// - previousBestSession: (선택) 이전 최고 기록 세션
/// - previousProgress: 세션 시작 직전 Progress (게이지 전 상태)
/// - updatedProgress: 세션 후 저장된 Progress (게이지 후 상태)
/// - reportModel: 순수 데이터 레벨 리포트(하이라이트 등)
class TrainingReportViewModel {
  final TrainingSessionModel currentSession;
  final TrainingSessionModel? previousBestSession;

  final TrainingProgressModel? previousProgress;
  final TrainingProgressModel updatedProgress;

  final TrainingReportModel reportModel;

  const TrainingReportViewModel({
    required this.currentSession,
    required this.previousBestSession,
    required this.previousProgress,
    required this.updatedProgress,
    required this.reportModel,
  });
}
