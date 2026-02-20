class MathLogic {
  /// Calculates Stress Level percentage (0-100) based on BPM.
  /// 
  /// Logic:
  /// - BPM < 60: 0-10% (Resting/Low)
  /// - 60 <= BPM < 80: 10-30% (Normal)
  /// - 80 <= BPM < 100: 30-60% (Elevated)
  /// - 100 <= BPM < 120: 60-90% (High)
  /// - BPM >= 120: 90-100% (Extreme)
  static double calculateStress(int bpm) {
    if (bpm < 60) {
      return ((bpm / 60) * 10).clamp(0.0, 10.0); 
    } else if (bpm < 80) {
      // Map 60-80 to 10-30
      return 10 + (((bpm - 60) / 20) * 20);
    } else if (bpm < 100) {
      // Map 80-100 to 30-60
      return 30 + (((bpm - 80) / 20) * 30);
    } else if (bpm < 120) {
      // Map 100-120 to 60-90
      return 60 + (((bpm - 100) / 20) * 30);
    } else {
      // Map 120+ to 90-100, max 100
      double val = 90 + (((bpm - 120) / 40) * 10);
      return val > 100 ? 100.0 : val;
    }
  }

  /// Determines Anxiety Status based on Stress Level.
  static String determineAnxiety(double stressLevel) {
    if (stressLevel < 30) {
      return "CALM";
    } else if (stressLevel < 70) {
      return "ELEVATED";
    } else {
      return "HIGH";
    }
  }
}
