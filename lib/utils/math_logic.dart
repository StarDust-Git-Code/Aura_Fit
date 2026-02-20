class MathLogic {
  /// Maps BPM → Stress % (0–100).
  static double calculateStress(int bpm) {
    if (bpm < 60) {
      return (bpm / 60 * 10).clamp(0.0, 10.0);
    } else if (bpm < 80) {
      return 10 + ((bpm - 60) / 20 * 20);
    } else if (bpm < 100) {
      return 30 + ((bpm - 80) / 20 * 30);
    } else if (bpm < 120) {
      return 60 + ((bpm - 100) / 20 * 30);
    } else {
      return (90 + ((bpm - 120) / 40 * 10)).clamp(0.0, 100.0);
    }
  }

  /// Maps Stress % → Anxiety label.
  static String determineAnxiety(double stressLevel) {
    if (stressLevel < 30) return "CALM";
    if (stressLevel < 70) return "ELEVATED";
    return "HIGH";
  }

  /// Returns a personalized recovery recommendation.
  static String getRecommendation(String anxietyStatus, int bpm) {
    switch (anxietyStatus) {
      case "CALM":
        return "You're doing great! Keep up your healthy rhythm. 💚";
      case "ELEVATED":
        if (bpm > 100) {
          return "Try box-breathing: inhale 4s → hold 4s → exhale 4s. 🧘";
        }
        return "Take a short break. Drink water and stretch. 🌿";
      case "HIGH":
        if (bpm > 130) {
          return "Stop activity immediately. Sit down, breathe slowly, and rest. 🚨";
        }
        return "Emergency: Practice slow deep breaths (5s in, 5s out). Seek calm. 🆘";
      default:
        return "";
    }
  }
}
