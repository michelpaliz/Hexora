// lib/f-themes/utilities/app_utils.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AppUtils {
  /// Load custom fonts
  static Future<void> loadCustomFonts() async {
    final fontLoader = FontLoader('bagel')
      ..addFont(rootBundle.load('assets/fonts/bagel_fat_one.ttf'));
    final fontLoader2 = FontLoader('lato')
      ..addFont(rootBundle.load('assets/fonts/lato.ttf'));
    final fontLoader3 = FontLoader('righteous')
      ..addFont(rootBundle.load('assets/fonts/righteous.ttf'));

    await fontLoader.load();
    await fontLoader2.load();
    await fontLoader3.load();
  }

  /// Address suggestions for search bar (Nominatim)
  static Future<List<String>> getAddressSuggestions(String pattern) async {
    final baseUrl = Uri.parse('https://nominatim.openstreetmap.org/search');
    final query = {'format': 'json', 'q': pattern};

    final res = await http.get(baseUrl.replace(queryParameters: query));
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List<dynamic>;
      return data.map((e) => (e['display_name'] as String)).toList();
    }
    throw Exception('Failed to load suggestions');
  }

  /// Capitalize first letter
  static String capitalize(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);

  /// Guess user locale by coarse location (ES for S. America, otherwise EN)
  static Future<Locale> getUserLocale() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      if (pos.latitude >= -56.0 &&
          pos.latitude <= 11.0 &&
          pos.longitude >= -77.8 &&
          pos.longitude <= -34.8) {
        return const Locale('es');
      }
      return const Locale('en');
    } catch (_) {
      return const Locale('en');
    }
  }

  /// Generate random alphanumeric id of [length]
  static String generateRandomId(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Month name and abbreviation helpers
  static String getMonthDate(int m) => switch (m) {
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December',
        _ => '',
      };

  static String getMonthAbbreviation(int m) => switch (m) {
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec',
        _ => '',
      };

  /// Format like "Apr 29, 2025"
  static String formatDate(DateTime date) =>
      "${getMonthAbbreviation(date.month)} ${date.day}, ${date.year}";
}
