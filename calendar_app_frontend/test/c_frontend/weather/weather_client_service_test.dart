import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/utils/weather/weather_api_client.dart';
import 'package:hexora/c-frontend/utils/weather/weather_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WeatherApiClient.buildForecastUri', () {
    test('uses the supplied location as an encoded endpoint segment', () {
      final uri = WeatherApiClient().buildForecastUri(
        location: 'Dénia / Marina',
        days: 5,
      );

      expect(uri.pathSegments, ['api', 'weather', 'Dénia / Marina']);
      expect(uri.queryParameters, {'days': '5'});
    });
  });

  test(
    'WeatherService caches forecasts separately by normalized location',
    () async {
      final requestedUris = <Uri>[];
      final service = WeatherService(
        apiClient: WeatherApiClient(
          httpClient: MockClient((request) async {
            requestedUris.add(request.url);
            return http.Response(
              jsonEncode({
                'location': request.url.pathSegments.last,
                'forecast': [
                  {
                    'date': '2030-01-01',
                    'minTemp': 10,
                    'maxTemp': 20,
                    'rainProbability': 0,
                    'windSpeed': 5,
                    'skyDescription': 'Sunny',
                  },
                ],
              }),
              200,
            );
          }),
        ),
      );

      await service.fetchWeatherBundle(
        location: 'Weather Test D%C3%A9nia',
        days: 1,
      );
      await service.fetchWeatherBundle(
        location: 'Weather Test València',
        days: 1,
      );
      await service.fetchWeatherBundle(
        location: 'Weather Test Dénia',
        days: 1,
      );

      expect(requestedUris, hasLength(2));
      expect(requestedUris[0].pathSegments.last, 'Weather Test Dénia');
      expect(requestedUris[1].pathSegments.last, 'Weather Test València');

      service.dispose();
    },
  );
}
