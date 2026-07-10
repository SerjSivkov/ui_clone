/// Live progress while vision analysis runs.
enum AnalysisPhase {
  /// Compressing / encoding screenshots locally.
  preparing,

  /// Uploading request body to the provider.
  uploading,

  /// Waiting for the model response.
  waiting,
}

class AnalysisProgress {
  const AnalysisProgress({
    required this.phase,
    required this.imagesDone,
    required this.imagesTotal,
    required this.fraction,
    this.etaSec,
  });

  final AnalysisPhase phase;
  final int imagesDone;
  final int imagesTotal;

  /// Overall 0..1 estimate across prepare → upload → wait.
  final double fraction;

  /// Rough seconds remaining; null when unknown.
  final int? etaSec;

  String get phaseLabel => switch (phase) {
        AnalysisPhase.preparing => 'Подготовка изображений',
        AnalysisPhase.uploading => 'Отправка в AI',
        AnalysisPhase.waiting => 'Ждём ответ модели',
      };

  String get detailLabel {
    final images = imagesTotal > 0
        ? '$imagesDone/$imagesTotal'
        : '$imagesDone';
    final eta = etaSec == null
        ? null
        : etaSec! <= 0
            ? 'скоро'
            : '~$etaSec с';
    return switch (phase) {
      AnalysisPhase.preparing =>
        eta == null ? 'Сжатие $images' : 'Сжатие $images · $eta',
      AnalysisPhase.uploading =>
        eta == null ? 'Загрузка $images' : 'Загрузка $images · $eta',
      AnalysisPhase.waiting =>
        eta == null ? 'Анализ $images фото' : 'Анализ $images фото · $eta',
    };
  }
}

class AnalysisCancelledException implements Exception {
  const AnalysisCancelledException([this.message = 'Анализ отменён']);

  final String message;

  @override
  String toString() => message;
}
