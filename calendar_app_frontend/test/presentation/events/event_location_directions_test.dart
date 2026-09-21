import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/events/screens/event_screen/event_detail/event_detail_screen.dart';

void main() {
  test('event location builds an encoded Google Maps directions URL', () {
    final uri = buildEventDirectionsUri('Calle Mayor 12, Dénia');

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {
      'api': '1',
      'destination': 'Calle Mayor 12, Dénia',
    });
  });
}
