import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_meteo/open_meteo.dart';

/// Koordinaten Böhmenkirch 89558 (näherungsweise, für Open-Meteo).
const double kBoehmenkirchLat = 48.6814;
const double kBoehmenkirchLon = 9.9342;

/// Anzeige in der Überschrift.
const String kBoehmenkirchLocationTitle = 'Böhmenkirch';

/// Feste Kartengröße (logische Pixel, 4:3) — ändert sich nicht mit Fensterbreite.
/// Faktor 2 gegenüber der ursprünglichen 260 px-Breite.
const double kBoehmenkirchWeatherCardWidth = 520;
const double kBoehmenkirchWeatherCardHeight =
    kBoehmenkirchWeatherCardWidth * 3 / 4;

const double _weatherCardRadius = 32;
const double _weatherCardElevation = 8;

const _userAgent = 'DoorDesk/1.0 (Metisia)';

DateTime _mondayOfWeek(DateTime reference) {
  final day = DateTime(reference.year, reference.month, reference.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime _sundayDateOfWeek(DateTime monday) =>
    monday.add(const Duration(days: 6));

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _asLocalDate(DateTime t) => DateTime(t.year, t.month, t.day);

@immutable
class BoehmenkirchDayForecast {
  const BoehmenkirchDayForecast({
    required this.date,
    required this.wmoCode,
    required this.minC,
    required this.maxC,
  });

  final DateTime date;
  final int wmoCode;
  final int minC;
  final int maxC;
}

@immutable
class BoehmenkirchWeatherBundle {
  const BoehmenkirchWeatherBundle({
    required this.currentTempC,
    required this.currentWmoCode,
    required this.todayWeekdayDe,
    required this.days,
  });

  final int currentTempC;
  final int currentWmoCode;
  final String todayWeekdayDe;
  final List<BoehmenkirchDayForecast> days;
}

Future<BoehmenkirchWeatherBundle> _fetchWeatherBundle() async {
  final now = DateTime.now();
  final monday = _mondayOfWeek(now);
  final sunday = _sundayDateOfWeek(monday);

  const api = WeatherApi(
    userAgent: _userAgent,
    temperatureUnit: TemperatureUnit.celsius,
    windspeedUnit: WindspeedUnit.kmh,
  );

  final response = await api.request(
    locations: {
      OpenMeteoLocation(
        latitude: kBoehmenkirchLat,
        longitude: kBoehmenkirchLon,
        startDate: monday,
        endDate: sunday,
      ),
    },
    daily: const {
      WeatherDaily.weather_code,
      WeatherDaily.temperature_2m_max,
      WeatherDaily.temperature_2m_min,
    },
    current: const {WeatherCurrent.temperature_2m, WeatherCurrent.weather_code},
  );

  final seg = response.segments.first;
  final codes = seg.dailyData[WeatherDaily.weather_code]?.values ?? {};
  final maxT = seg.dailyData[WeatherDaily.temperature_2m_max]?.values ?? {};
  final minT = seg.dailyData[WeatherDaily.temperature_2m_min]?.values ?? {};

  final byDate = <DateTime, BoehmenkirchDayForecast>{};
  for (final key in codes.keys) {
    final d = _asLocalDate(key);
    final c = codes[key]!.round();
    final mxRaw = maxT[key];
    final mnRaw = minT[key];
    var mx = mxRaw?.round() ?? mnRaw?.round() ?? 0;
    var mn = mnRaw?.round() ?? mxRaw?.round() ?? 0;
    if (mn > mx) {
      final t = mn;
      mn = mx;
      mx = t;
    }
    byDate[d] = BoehmenkirchDayForecast(
      date: d,
      wmoCode: c,
      minC: mn,
      maxC: mx,
    );
  }

  final out = <BoehmenkirchDayForecast>[];
  for (var i = 0; i < 7; i++) {
    final d = monday.add(Duration(days: i));
    out.add(
      byDate[d] ??
          BoehmenkirchDayForecast(date: d, wmoCode: 3, minC: 0, maxC: 0),
    );
  }

  var todayFc = out.first;
  for (final d in out) {
    if (_isSameDate(d.date, now)) {
      todayFc = d;
      break;
    }
  }

  final curTVal = seg.currentData[WeatherCurrent.temperature_2m]?.value;
  final curWmoVal = seg.currentData[WeatherCurrent.weather_code]?.value;

  final currentTempC = curTVal != null ? curTVal.round() : todayFc.maxC;
  final currentWmoCode = curWmoVal != null
      ? curWmoVal.round()
      : todayFc.wmoCode;

  final todayWeekdayDe = DateFormat('EEEE', 'de_DE').format(now);

  return BoehmenkirchWeatherBundle(
    currentTempC: currentTempC,
    currentWmoCode: currentWmoCode,
    todayWeekdayDe: todayWeekdayDe,
    days: out,
  );
}

final boehmenkirchWeekWeatherProvider =
    FutureProvider.autoDispose<BoehmenkirchWeatherBundle>((ref) {
      return _fetchWeatherBundle();
    });

LinearGradient _gradientForWmo(int code) {
  return switch (code) {
    0 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF9E6), Color(0xFFB3E5FC)],
    ),
    1 || 2 || 3 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
    ),
    45 || 48 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE0E0E0), Color(0xFFB0BEC5)],
    ),
    >= 51 && <= 67 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFBBDEFB), Color(0xFF90CAF9)],
    ),
    >= 71 && <= 77 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8EAF6), Color(0xFFFFFFFF)],
    ),
    >= 80 && <= 86 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB3E5FC), Color(0xFF64B5F6)],
    ),
    >= 95 => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD1C4E9), Color(0xFF9FA8DA)],
    ),
    _ => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
    ),
  };
}

IconData _iconForWmo(int code) {
  return switch (code) {
    0 => Icons.wb_sunny_rounded,
    1 || 2 || 3 => Icons.wb_cloudy_rounded,
    45 || 48 => Icons.blur_on_rounded,
    >= 51 && <= 55 => Icons.grain_rounded,
    >= 56 && <= 67 => Icons.water_drop_rounded,
    >= 71 && <= 77 => Icons.ac_unit_rounded,
    >= 80 && <= 82 => Icons.umbrella_rounded,
    >= 85 && <= 86 => Icons.cloudy_snowing,
    >= 95 => Icons.thunderstorm_rounded,
    _ => Icons.cloud_outlined,
  };
}

Color _iconColorForWmo(int code) {
  return switch (code) {
    0 => const Color(0xFFFFA000),
    1 || 2 || 3 => const Color(0xFF546E7A),
    45 || 48 => const Color(0xFF78909C),
    >= 51 && <= 67 => const Color(0xFF1976D2),
    >= 71 && <= 77 => const Color(0xFF0288D1),
    >= 80 && <= 86 => const Color(0xFF1565C0),
    >= 95 => const Color(0xFF5E35B1),
    _ => const Color(0xFF607D8B),
  };
}

/// Wetter Böhmenkirch: Zielgröße bis [kBoehmenkirchWeatherCardWidth] (4:3), skaliert bei schmaler Spalte runter.
/// Daten: Open-Meteo.
class BoehmenkirchWeekWeatherCard extends ConsumerWidget {
  const BoehmenkirchWeekWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(boehmenkirchWeekWeatherProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = min(kBoehmenkirchWeatherCardWidth, constraints.maxWidth);
        final cardH = cardW * 3 / 4;

        return async.when(
          data: (bundle) {
            final today = DateTime.now();
            final grad = _gradientForWmo(bundle.currentWmoCode);
            return SizedBox(
              width: cardW,
              height: cardH,
              child: Material(
                color: Colors.transparent,
                elevation: _weatherCardElevation,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(_weatherCardRadius),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_weatherCardRadius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: grad),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kBoehmenkirchLocationTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 36,
                              color: const Color(0xFF263238),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            '89558',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 24,
                              color: const Color(0xFF546E7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${bundle.currentTempC}°',
                                      style: theme.textTheme.displayMedium
                                          ?.copyWith(
                                            fontSize: 96,
                                            height: 0.95,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF1565C0),
                                            letterSpacing: -3,
                                          ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        bundle.todayWeekdayDe,
                                        textAlign: TextAlign.end,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 40,
                                              height: 1.05,
                                              color: const Color(0xFF37474F),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        _iconForWmo(bundle.currentWmoCode),
                                        size: 68,
                                        color: _iconColorForWmo(
                                          bundle.currentWmoCode,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              for (final day in bundle.days)
                                Expanded(
                                  child: _DayChip(
                                    day: day,
                                    isToday: _isSameDate(day.date, today),
                                    theme: theme,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => SizedBox(
            width: cardW,
            height: cardH,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(_weatherCardRadius),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_weatherCardRadius),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          error: (Object? error, StackTrace stackTrace) => SizedBox(
            width: cardW,
            height: cardH,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(_weatherCardRadius),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_weatherCardRadius),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () =>
                        ref.invalidate(boehmenkirchWeekWeatherProvider),
                    child: const Center(
                      child: Icon(Icons.refresh_rounded, size: 56),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isToday,
    required this.theme,
  });

  final BoehmenkirchDayForecast day;
  final bool isToday;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.E(
      'de_DE',
    ).format(day.date).replaceAll('.', '').toUpperCase();
    final grad = _gradientForWmo(day.wmoCode);
    final icon = _iconForWmo(day.wmoCode);
    final iconCol = _iconColorForWmo(day.wmoCode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(24),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 4)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 4),
              Icon(icon, size: 36, color: iconCol),
              const SizedBox(height: 4),
              Text(
                '${day.minC}° ${day.maxC}°',
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF455A64),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
