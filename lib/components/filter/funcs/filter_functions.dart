import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tmdss/components/filter/var/filter_variables.dart';

final supabase = Supabase.instance.client;

Future<List<Map<String, dynamic>>> fetchRegionsData() async {
  try {
    final data = await supabase.from('regions').select('region_num, region_name');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    print('Error fetching regions: $e');
    return [];
  }
}

Future<List<String>> fetchProvinces(String year, String region) async {
  try {
    final data = await supabase
        .from('training_info_$year')
        .select('province')
        .eq('region_num', region);
    return data.map<String>((e) => e['province'] as String).toSet().toList()
      ..sort();
  } catch (e) {
    print('Error fetching provinces for year $year: $e');
    return [];
  }
}

Future<List<String>> fetchProvincesAcrossAllYears(String region) async {
  Set<String> allProvinces = {};
  for (String yr in years) {
    try {
      final data = await supabase
          .from('training_info_$yr')
          .select('province')
          .eq('region_num', region);
      allProvinces.addAll(data.map<String>((e) => e['province'] as String));
    } catch (e) {
      print('Error fetching provinces for year $yr: $e');
    }
  }
  List<String> sortedProvinces = allProvinces.toList()..sort();
  return sortedProvinces;
}

Future<List<String>> fetchCities(String year, String province) async {
  try {
    final data = await supabase
        .from('training_info_$year')
        .select('city')
        .eq('province', province);
    return data.map<String>((e) => e['city'] as String).toSet().toList()
      ..sort();
  } catch (e) {
    print('Error fetching cities for year $year: $e');
    return [];
  }
}

Future<List<String>> fetchCitiesAcrossAllYears(String province) async {
  Set<String> allCities = {};
  for (String yr in years) {
    try {
      final data = await supabase
          .from('training_info_$yr')
          .select('city')
          .eq('province', province);
      allCities.addAll(data.map<String>((e) => e['city'] as String));
    } catch (e) {
      print('Error fetching cities for year $yr: $e');
    }
  }
  List<String> sortedCities = allCities.toList()..sort();
  return sortedCities;
}

Future<List<Map<String, dynamic>>> fetchTrainingData({
  String? year,
  String? region,
  String? province,
  String? city,
  String? startMonth,
  String? endMonth,
}) async {
  if ([year, region, province, city, startMonth, endMonth]
      .every((v) => v == null || v.isEmpty)) {
    return [];
  }

  List<Map<String, dynamic>> allResults = [];
  List<String> targetYears = year != null ? [year] : years;

  for (String yr in targetYears) {
    try {
      var query = supabase
          .from('training_info_$yr')
          .select('act_title, venue, start_date, end_date, city, province');

      if (region != null && region.isNotEmpty) {
        query = query.eq('region_num', region);
      }
      if (province != null && province.isNotEmpty) {
        query = query.eq('province', province);
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      if (startMonth != null && startMonth.isNotEmpty) {
        final startMonthNumber = int.parse(monthMap[startMonth]!);
        final startDate = DateTime(int.parse(yr), startMonthNumber, 1);
        late DateTime endDate;

        if (endMonth != null && endMonth.isNotEmpty) {
          final endMonthIndex = months.indexOf(endMonth);
          endDate = DateTime(int.parse(yr), endMonthIndex + 2, 1);
        } else {
          endDate = DateTime(startDate.year, startDate.month + 1, 1);
        }

        query = query
            .gte('start_date', startDate.toIso8601String())
            .lt('start_date', endDate.toIso8601String());
      }

      final data = await query.order('start_date');
      allResults.addAll(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      print('Error fetching training data for year $yr: $e');
    }
  }

  allResults.sort((a, b) => DateTime.parse(a['start_date'])
      .compareTo(DateTime.parse(b['start_date'])));

  return allResults;
}
