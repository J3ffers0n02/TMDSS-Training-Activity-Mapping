import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

List<String> years = []; // Initialize as empty

Future<void> initializeYears() async {
  try {
    final result = await supabase.rpc('get_training_tables').select();
    years = result
        .where((item) => item.containsKey('table_name'))
        .map((item) {
          final tableName = item['table_name'].toString();
          final yearMatch = RegExp(r'training_info_(\d{4})').firstMatch(tableName);
          return yearMatch?.group(1);
        })
        .where((year) => year != null)
        .cast<String>()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
    } catch (e) {
    print('Error fetching years: $e');
    years = ['2023', '2024']; // Fallback to safe years
  }
}

List<String> months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

final Map<String, String> monthMap = {
  'Jan': '01',
  'Feb': '02',
  'Mar': '03',
  'Apr': '04',
  'May': '05',
  'Jun': '06',
  'Jul': '07',
  'Aug': '08',
  'Sep': '09',
  'Oct': '10',
  'Nov': '11',
  'Dec': '12',
};