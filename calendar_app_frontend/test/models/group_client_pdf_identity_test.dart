import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/clients/client.dart';

void main() {
  test('preserves the PDF prefix and alias in customer JSON', () {
    final client = GroupClient.fromJson(const {
      '_id': 'client-1',
      'name': 'Residencial Norte',
      'pdfPrefix': 'Com. de Prop.',
      'pdfAlias': 'Las Alondras',
    });

    expect(client.pdfPrefix, 'Com. de Prop.');
    expect(client.pdfAlias, 'Las Alondras');
    expect(client.toJson()['pdfPrefix'], 'Com. de Prop.');
    expect(client.toJson()['pdfAlias'], 'Las Alondras');
  });
}
