import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinitboard/core/config_service.dart';
import 'package:myinitboard/features/weather/models/location_config.dart';
import 'package:myinitboard/features/weather/models/weather_code_helper.dart';
import 'package:myinitboard/features/weather/models/weather_data.dart';
import 'package:myinitboard/features/weather/services/geocoding_service.dart';
import 'package:myinitboard/features/weather/views/widgets/location_weather_card.dart';
import 'package:myinitboard/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default locations when no preferences exist', () async {
      final locs = await ConfigService.loadLocations();
      expect(locs.length, equals(2));
      expect(locs[0].name, equals('東京'));
      expect(locs[0].lat, equals(35.6895));
      expect(locs[0].lon, equals(139.6917));

      expect(locs[1].name, equals('大阪'));
      expect(locs[1].lat, equals(34.6937));
      expect(locs[1].lon, equals(135.5023));
    });

    test('Saves custom locations and retrieves them with priority', () async {
      final customList = [
        const LocationConfig(
          id: 'loc_1',
          name: '自宅',
          placeName: '横浜市',
          lat: 35.4437,
          lon: 139.6380,
        ),
        const LocationConfig(
          id: 'loc_2',
          name: '実家',
          placeName: '京都市',
          lat: 35.0116,
          lon: 135.7681,
        ),
        const LocationConfig(
          id: 'loc_3',
          name: '別荘',
          placeName: '軽井沢町',
          lat: 36.3488,
          lon: 138.6358,
        ),
      ];

      await ConfigService.saveLocations(customList);

      final reloaded = await ConfigService.loadLocations();
      expect(reloaded.length, equals(3));
      expect(reloaded[0].name, equals('自宅'));
      expect(reloaded[0].placeName, equals('横浜市'));
      expect(reloaded[1].name, equals('実家'));
      expect(reloaded[2].name, equals('別荘'));
    });

    test('Reset locations reverts to defaults', () async {
      final customList = [
        const LocationConfig(id: 'loc_fukuoka', name: '福岡', lat: 33.5904, lon: 130.4017),
      ];
      await ConfigService.saveLocations(customList);

      await ConfigService.resetLocations();

      final reloaded = await ConfigService.loadLocations();
      expect(reloaded.length, equals(2));
      expect(reloaded[0].name, equals('東京'));
      expect(reloaded[1].name, equals('大阪'));
    });
  });

  group('GeocodingResult Unit Tests', () {
    test('Parses JSON and creates clean display name', () {
      final json = {
        'name': '横浜市',
        'latitude': 35.4333,
        'longitude': 139.6500,
        'country': '日本',
        'admin1': '神奈川県',
      };
      final result = GeocodingResult.fromJson(json);
      expect(result.name, equals('横浜市'));
      expect(result.latitude, equals(35.4333));
      expect(result.longitude, equals(139.6500));
      expect(result.displayName, equals('横浜市 (神奈川県)'));
    });

    test('Handles international city display name', () {
      final json = {
        'name': 'Paris',
        'latitude': 48.8566,
        'longitude': 2.3522,
        'country': 'フランス',
        'admin1': 'イル＝ド＝フランス',
      };
      final result = GeocodingResult.fromJson(json);
      expect(result.displayName, equals('Paris (イル＝ド＝フランス, フランス)'));
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

    testWidgets('Renders iPad mini 6 Landscape layout (1133x744pt) with LocationTabBar', (WidgetTester tester) async {
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

      // Location tab bar is present with registered locations and Add button
      expect(find.text('東京'), findsOneWidget);
      expect(find.text('大阪'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);

      // Tap on '大阪' tab
      await tester.tap(find.text('大阪'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on '東京' tab
      await tester.tap(find.text('東京'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Renders iPad mini 6 Portrait layout (744x1133pt)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(744, 1133);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyInitBoardApp());
      await tester.pump(const Duration(milliseconds: 200));

      // In portrait, location tabs are displayed and accessible
      expect(find.text('東京'), findsOneWidget);
      expect(find.text('大阪'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);

      // Tap on '大阪' tab
      await tester.tap(find.text('大阪'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Settings Dialog opens, shows location fields, add button, and dialog actions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1133, 744);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyInitBoardApp());
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Settings gear icon
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify dialog contents
      expect(find.text('登録地点の管理'), findsOneWidget);
      expect(find.text('地点 1'), findsOneWidget);
      expect(find.text('地点 2'), findsOneWidget);
      expect(find.text('新しい地点を追加'), findsOneWidget);
      expect(find.text('初期値に戻す'), findsOneWidget);
      expect(find.text('保存して再取得'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);

      // Tap Add New Location button
      await tester.tap(find.text('新しい地点を追加'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('地点 3'), findsOneWidget);

      // Close dialog via close icon button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('登録地点の管理'), findsNothing);
    });

    testWidgets('Toggles between hourly and daily forecast views in LocationWeatherCard', (WidgetTester tester) async {
      int activeForecastTab = 0;
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final dummyWeather = LocationWeatherData.fromOpenMeteoJson(
        location: const LocationConfig(id: 'left', name: '東京', lat: 35.6895, lon: 139.6917),
        json: {
          'current': {
            'time': "${todayStr}T12:00",
            'temperature_2m': 18.0,
            'weather_code': 0,
          },
          'hourly': {
            'time': ["${todayStr}T12:00"],
            'temperature_2m': [18.0],
            'weather_code': [0],
          },
          'daily': {
            'time': [todayStr],
            'weather_code': [0],
            'temperature_2m_max': [20.0],
            'temperature_2m_min': [10.0],
          },
        },
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return LocationWeatherCard(
                data: dummyWeather,
                isLoading: false,
                isLandscape: true,
                forecastTab: activeForecastTab,
                onForecastTabChanged: (newTab) => setState(() => activeForecastTab = newTab),
              );
            },
          ),
        ),
      ));
      await tester.pump();

      // Displays '1時間毎' and '1日毎' toggle buttons
      expect(find.text('1時間毎'), findsOneWidget);
      expect(find.text('1日毎'), findsOneWidget);

      // Tap on '1日毎'
      await tester.tap(find.text('1日毎'));
      await tester.pump(const Duration(milliseconds: 250));

      // 7日間の日別予報テキストが表示されている
      expect(find.text('7日間の日別予報'), findsOneWidget);

      // Tap back to '1時間毎'
      await tester.tap(find.text('1時間毎'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('1時間ごとの予報（明日24時まで）'), findsOneWidget);
    });
  });
}
