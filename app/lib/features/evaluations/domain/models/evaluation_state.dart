/// Represents the current state of the evaluation process
enum EvaluationState {
  /// Initial state, preparing image
  loading,

  /// Detecting objects in the image
  detecting,

  /// Extracting crops from detections
  extractingCrops,

  /// Showing crop gallery for review
  reviewingCrops,

  /// Running classification on selected crops
  classifying,

  /// Showing final results
  showingResults,

  /// An error occurred
  error,
}

/// Extension methods for EvaluationState
extension EvaluationStateX on EvaluationState {
  /// Get user-friendly message for this state
  String get message {
    switch (this) {
      case EvaluationState.loading:
        return 'Preparando imagen...';
      case EvaluationState.detecting:
        return 'Detectando objetos...';
      case EvaluationState.extractingCrops:
        return 'Extrayendo recortes...';
      case EvaluationState.reviewingCrops:
        return 'Revisión de detecciones';
      case EvaluationState.classifying:
        return 'Clasificando...';
      case EvaluationState.showingResults:
        return 'Resultados';
      case EvaluationState.error:
        return 'Error';
    }
  }

  /// Whether this state shows a loading indicator
  bool get isProcessing {
    switch (this) {
      case EvaluationState.loading:
      case EvaluationState.detecting:
      case EvaluationState.extractingCrops:
      case EvaluationState.classifying:
        return true;
      case EvaluationState.reviewingCrops:
      case EvaluationState.showingResults:
      case EvaluationState.error:
        return false;
    }
  }
}
