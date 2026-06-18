class SpainPostalCodeAutofillResult {
  final String province;
  final String country;

  const SpainPostalCodeAutofillResult({
    required this.province,
    this.country = 'España',
  });
}

const Map<String, String> _provinceByPostalPrefix = {
  '01': 'Alava',
  '02': 'Albacete',
  '03': 'Alicante',
  '04': 'Almeria',
  '05': 'Avila',
  '06': 'Badajoz',
  '07': 'Illes Balears',
  '08': 'Barcelona',
  '09': 'Burgos',
  '10': 'Caceres',
  '11': 'Cadiz',
  '12': 'Castellon',
  '13': 'Ciudad Real',
  '14': 'Cordoba',
  '15': 'A Coruna',
  '16': 'Cuenca',
  '17': 'Girona',
  '18': 'Granada',
  '19': 'Guadalajara',
  '20': 'Gipuzkoa',
  '21': 'Huelva',
  '22': 'Huesca',
  '23': 'Jaen',
  '24': 'Leon',
  '25': 'Lleida',
  '26': 'La Rioja',
  '27': 'Lugo',
  '28': 'Madrid',
  '29': 'Malaga',
  '30': 'Murcia',
  '31': 'Navarra',
  '32': 'Ourense',
  '33': 'Asturias',
  '34': 'Palencia',
  '35': 'Las Palmas',
  '36': 'Pontevedra',
  '37': 'Salamanca',
  '38': 'Santa Cruz de Tenerife',
  '39': 'Cantabria',
  '40': 'Segovia',
  '41': 'Sevilla',
  '42': 'Soria',
  '43': 'Tarragona',
  '44': 'Teruel',
  '45': 'Toledo',
  '46': 'Valencia',
  '47': 'Valladolid',
  '48': 'Bizkaia',
  '49': 'Zamora',
  '50': 'Zaragoza',
  '51': 'Ceuta',
  '52': 'Melilla',
};

String _normalizeCountry(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
}

String? normalizeSpanishPostalCode(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 5) return null;
  return digits;
}

bool isSpainCountry(String raw) {
  final normalized = _normalizeCountry(raw);
  return normalized == 'espana' || normalized == 'spain';
}

SpainPostalCodeAutofillResult? inferSpainPostalAutofill({
  required String postalCode,
  String? currentCountry,
}) {
  final normalizedPostal = normalizeSpanishPostalCode(postalCode);
  if (normalizedPostal == null) return null;

  final normalizedCountry = _normalizeCountry(currentCountry ?? '');
  if (normalizedCountry.isNotEmpty &&
      normalizedCountry != 'espana' &&
      normalizedCountry != 'spain') {
    return null;
  }

  final province = _provinceByPostalPrefix[normalizedPostal.substring(0, 2)];
  if (province == null) return null;

  return SpainPostalCodeAutofillResult(province: province);
}
