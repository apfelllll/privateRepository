import 'package:shared_preferences/shared_preferences.dart';

abstract final class CalculationSettingsKeys {
  static const meisterHourlyRate = 'settings.calculation.meister_hourly_rate';
  static const geselleHourlyRate = 'settings.calculation.geselle_hourly_rate';
  static const bankraumFactor = 'settings.calculation.bankraum_factor';
  static const maschinenraumFactor =
      'settings.calculation.maschinenraum_factor';
  static const lackierraumFactor = 'settings.calculation.lackierraum_factor';
  static const planungFactor = 'settings.calculation.planung_factor';
  static const montageFactor = 'settings.calculation.montage_factor';
}

class CalculationSettings {
  const CalculationSettings({
    required this.meisterHourlyRate,
    required this.geselleHourlyRate,
    required this.bankraumFactor,
    required this.maschinenraumFactor,
    required this.lackierraumFactor,
    required this.planungFactor,
    required this.montageFactor,
  });

  final double meisterHourlyRate;
  final double geselleHourlyRate;
  final double bankraumFactor;
  final double maschinenraumFactor;
  final double lackierraumFactor;
  final double planungFactor;
  final double montageFactor;

  static const defaults = CalculationSettings(
    meisterHourlyRate: 0,
    geselleHourlyRate: 0,
    bankraumFactor: 1,
    maschinenraumFactor: 1,
    lackierraumFactor: 1,
    planungFactor: 1,
    montageFactor: 1,
  );

  static Future<CalculationSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return CalculationSettings(
      meisterHourlyRate:
          p.getDouble(CalculationSettingsKeys.meisterHourlyRate) ??
              defaults.meisterHourlyRate,
      geselleHourlyRate:
          p.getDouble(CalculationSettingsKeys.geselleHourlyRate) ??
              defaults.geselleHourlyRate,
      bankraumFactor: p.getDouble(CalculationSettingsKeys.bankraumFactor) ??
          defaults.bankraumFactor,
      maschinenraumFactor:
          p.getDouble(CalculationSettingsKeys.maschinenraumFactor) ??
              defaults.maschinenraumFactor,
      lackierraumFactor:
          p.getDouble(CalculationSettingsKeys.lackierraumFactor) ??
              defaults.lackierraumFactor,
      planungFactor: p.getDouble(CalculationSettingsKeys.planungFactor) ??
          defaults.planungFactor,
      montageFactor: p.getDouble(CalculationSettingsKeys.montageFactor) ??
          defaults.montageFactor,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(
      CalculationSettingsKeys.meisterHourlyRate,
      meisterHourlyRate,
    );
    await p.setDouble(
      CalculationSettingsKeys.geselleHourlyRate,
      geselleHourlyRate,
    );
    await p.setDouble(
      CalculationSettingsKeys.bankraumFactor,
      bankraumFactor,
    );
    await p.setDouble(
      CalculationSettingsKeys.maschinenraumFactor,
      maschinenraumFactor,
    );
    await p.setDouble(
      CalculationSettingsKeys.lackierraumFactor,
      lackierraumFactor,
    );
    await p.setDouble(
      CalculationSettingsKeys.planungFactor,
      planungFactor,
    );
    await p.setDouble(
      CalculationSettingsKeys.montageFactor,
      montageFactor,
    );
  }

  CalculationSettings copyWith({
    double? meisterHourlyRate,
    double? geselleHourlyRate,
    double? bankraumFactor,
    double? maschinenraumFactor,
    double? lackierraumFactor,
    double? planungFactor,
    double? montageFactor,
  }) {
    return CalculationSettings(
      meisterHourlyRate: meisterHourlyRate ?? this.meisterHourlyRate,
      geselleHourlyRate: geselleHourlyRate ?? this.geselleHourlyRate,
      bankraumFactor: bankraumFactor ?? this.bankraumFactor,
      maschinenraumFactor: maschinenraumFactor ?? this.maschinenraumFactor,
      lackierraumFactor: lackierraumFactor ?? this.lackierraumFactor,
      planungFactor: planungFactor ?? this.planungFactor,
      montageFactor: montageFactor ?? this.montageFactor,
    );
  }
}
