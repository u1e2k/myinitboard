import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinitboard/core/config_service.dart';
import 'package:myinitboard/features/weather/models/location_config.dart';
import 'package:myinitboard/features/weather/models/weather_code_helper.dart';
import 'package:myinitboard/features/weather/models/weather_data.dart';
import 'package:myinitboard/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default locations when no preferences exist', () async {
      final locs = await ConfigService.loadLocations();
      expect(locs.left.name, equals('東京'));
      expect(locs.left.lat, equals(35.6895));
      expect(locs.left.lon, equals(139.6917));

      expect(locs.right.name, equals('大阪'));
      expect(locs.right.lat, equals(34.6937));
      expect(locs.right.lon, equals(135.5023));
    });

    test('Saves custom locations and retrieves them with priority', () async {
      const customLeft = LocationConfig(
        id: 'left',
        name: '横浜',
        lat: 35.4437,
        lon: 139.6380,
      );
      const customRight = LocationConfig(
        id: 'right',
        name: '京都',
        lat: 35.0116,
        lon: 135.7681,
      );

      await ConfigService.saveLocations(left: customLeft, right: customRight);

      final reloaded = await ConfigService.loadLocations();
      expect(reloaded.left.name, equals('横浜'));
      expect(reloaded.left.lat, equals(35.4437));
      expect(reloaded.right.name, equals('京都'));
      expect(reloaded.right.lat, equals(35.0116));
    });

    test('Reset locations reverts to defaults', () async {
      const customLeft = LocationConfig(id: 'left', name: '福岡', lat: 33.5904, lon: 130.4017);
      const customRight = LocationConfig(id: 'right', name: '札幌', lat: 43.0618, lon: 141.3545);
      await ConfigService.saveLocations(left: customLeft, right: customRight);

      await ConfigService.resetLocations();

      final reloaded = await ConfigService.loadLocations();
      expect(reloaded.left.name, equals('東京'));
      expect(reloaded.right.name, equals('大阪'));
    });
  });

  group('WeatherCodeHelper Unit Tests', () {
    test('Maps code 0 (Clear) properly', () {
      final dayInfo = WeatherCodeHelper.getInfo(0, isNight: false);
      expect(dayInfo.label, equals('快晴'));
      expect(dayInfo.icon, equals(Icons.wb_sunny_rounded));

      final nightInfo = WeatherCodeHelper.getInfo(0, isNight: true);
      expect(nightInfo.label, equals('快晴（夜）'));
      expect(nightInfo.icon, equals(Icons.nightlight_round));
    });

    test('Maps rain and snow codes properly', () {
      final rainInfo = WeatherCodeHelper.getInfo(63);
      expect(rainInfo.label, equals('雨'));
      expect(rainInfo.icon, equals(Icons.water_drop_rounded));

      final snowInfo = WeatherCodeHelper.getInfo(73);
      expect(snowInfo.label, equals('雪'));
      expect(snowInfo.icon, equals(Icons.ac_unit_rounded));
    });
  });

  group('WeatherData JSON parsing & Summary computation', () {
    test('Parses Open-Meteo JSON and calculates 6 period summaries correctly', () {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Generate dummy 48-hour hourly data
      List<String> times = [];
      List<double> temps = [];
      List<int> precips = [];
      List<int> codes = [];

      for (int day = 0; day < 3; day++) {
        final d = now.add(Duration(days: day));
        final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        for (int h = 0; h < 24; h++) {
          times.add("${dateStr}T${h.toString().padLeft(2, '0')}:00");
          temps.add(15.0 + (h % 5));
          precips.add(h >= 12 && h < 18 ? 60 : 10);
          codes.add(h >= 12 && h < 18 ? 61 : 0);
        }
      }

      final mockJson = {
        'current': {
          'time': "${todayStr}T12:00",
          'temperature_2m': 18.5,
          'apparent_temperature': 17.8,
          'relative_humidity_2m': 65,
          'weather_code': 1,
        },
        'hourly': {
          'time': times,
          'temperature_2m': temps,
          'precipitation_probability': precips,
          'weather_code': codes,
        },
        'daily': {
          'time': [todayStr],
          'weather_code': [1],
          'temperature_2m_max': [20.0],
          'temperature_2m_min': [12.0],
          'precipitation_probability_max': [60],
        },
      };

      const loc = LocationConfig(id: 'left', name: 'テスト地点', lat: 35.0, lon: 139.0);
      final weather = LocationWeatherData.fromOpenMeteoJson(
        location: loc,
        json: mockJson,
        fetchedAt: DateTime.now(),
      );

      expect(weather.current.temperature, equals(18.5));
      expect(weather.periodSummaries.length, equals(6));

      // Afternoon has 60% rain (>=50% alert)
      final afternoonSummary = weather.periodSummaries[1];
      expect(afternoonSummary.periodShort, equals('午後'));
      expect(afternoonSummary.maxPrecipitationProbability, equals(60));
      expect(afternoonSummary.isRainHigh, isTrue);

      // Morning has 10% rain
      final morningSummary = weather.periodSummaries[0];
      expect(morningSummary.periodShort, equals('午前'));
      expect(morningSummary.maxPrecipitationProbability, equals(10));
      expect(morningSummary.isRainHigh, isFalse);
    });
  });

  group('UI Responsive & iPad mini 6 Layout Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Renders iPad mini 6 Landscape layout (1133x744pt)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1133, 744);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyInitBoardApp());
      await tester.pump(const Duration(milliseconds: 200));

      // App title and header icons
      expect(find.text('myinitboard'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_customize_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // In landscape (width >= 850pt), segment control is not displayed
      expect(find.text('2地点並び'), findsNothing);
    });

    testWidgets('Renders iPad mini 6 Portrait layout (744x1133pt) with segment control', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(744, 1133);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyInitBoardApp());
      await tester.pump(const Duration(milliseconds: 200));

      // In portrait (width < 850pt), segment control is displayed
      expect(find.text('2地点並び'), findsOneWidget);
      expect(find.text('東京'), findsOneWidget);
      expect(find.text('大阪'), findsOneWidget);

      // Tap on '東京' segment tab
      await tester.tap(find.text('東京'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on '大阪' segment tab
      await tester.tap(find.text('大阪'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Settings Dialog opens, shows location fields and buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1133, 744);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyInitBoardApp());
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Settings gear icon
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify dialog contents
      expect(find.text('地点設定（プライベート設定）'), findsOneWidget);
      expect(find.text('地点1（左側）'), findsOneWidget);
      expect(find.text('地点2（右側）'), findsOneWidget);
      expect(find.text('初期値に戻す'), findsOneWidget);
      expect(find.text('保存して再取得'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);

      // Close dialog via cancel
      await tester.tap(find.text('キャンセル'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('地点設定（プライベート設定）'), findsNothing);
    });
  });
}
