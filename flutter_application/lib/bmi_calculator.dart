class BmiValidationException implements Exception {
  const BmiValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BmiAssessment {
  const BmiAssessment({required this.bmi, required this.recommendation});

  final double bmi;
  final String recommendation;
}

double? tryParseNumber(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String recommendationFor(double bmi) {
  if (bmi <= 16) {
    return 'Выраженный дефицит массы тела. Советуем набрать вес для здоровья.';
  }
  if (bmi < 18.5) {
    return 'Недостаточная масса тела. Рекомендуется увеличить массу тела.';
  }
  if (bmi < 25) {
    return 'Норма. Ваш вес в здоровом диапазоне — поддерживайте его!';
  }
  if (bmi < 30) {
    return 'Избыточная масса тела или предожирение. Желательно снизить вес для улучшения самочувствия.';
  }
  if (bmi < 35) {
    return 'Ожирение. Рекомендуется уменьшить вес под контролем специалиста.';
  }
  if (bmi < 40) {
    return 'Ожирение резкое. Необходимо снижение веса с медицинской поддержкой.';
  }
  return 'Очень резкое ожирение. Требуется срочная коррекция веса под наблюдением врача.';
}

BmiAssessment assessBmi({
  required String heightText,
  required String weightText,
}) {
  if (heightText.trim().isEmpty || weightText.trim().isEmpty) {
    throw const BmiValidationException('Заполните все поля');
  }

  final height = tryParseNumber(heightText);
  final weight = tryParseNumber(weightText);
  if (height == null || weight == null) {
    throw const BmiValidationException(
      'Введите числовые значения роста и веса',
    );
  }
  if (height <= 0 || weight <= 0) {
    throw const BmiValidationException('Рост и вес должны быть больше нуля');
  }

  final heightCm = height <= 3 ? height * 100 : height;
  if (heightCm < 50 || heightCm > 250) {
    throw const BmiValidationException(
      'Укажите рост в сантиметрах (50–250) или в метрах (0,5–2,5)',
    );
  }
  if (weight > 400) {
    throw const BmiValidationException('Укажите вес в килограммах (до 400)');
  }

  final meters = heightCm / 100;
  final raw = weight / (meters * meters);
  final bmi = double.parse(raw.toStringAsFixed(2));
  return BmiAssessment(bmi: bmi, recommendation: recommendationFor(bmi));
}

int measurementForStorage(double value) => value.round();

double heightToCentimeters(double height) =>
    height <= 3 ? height * 100 : height;
