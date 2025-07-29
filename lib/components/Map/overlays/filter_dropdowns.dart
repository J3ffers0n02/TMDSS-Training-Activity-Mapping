import 'package:flutter/material.dart';
import 'package:tmdss/helpers/my_dropdown.dart';

class DropdownFilters extends StatelessWidget {
  final List<String> years;
  final List<String> months;
  final List<Map<String, dynamic>> regions;
  final List<String> provinces;
  final List<String> cities;
  final String? selectedYear;
  final String? selectedRegion;
  final String? selectedProvince;
  final String? selectedCity;
  final String? selectedStartMonth;
  final String? selectedEndMonth;
  final void Function(String?) onYearChanged;
  final void Function(String?) onStartMonthChanged;
  final void Function(String?) onEndMonthChanged;
  final void Function(String?) onRegionChanged;
  final void Function(String?) onProvinceChanged;
  final void Function(String?) onCityChanged;

  const DropdownFilters({
    super.key,
    required this.years,
    required this.months,
    required this.regions,
    required this.provinces,
    required this.cities,
    required this.selectedYear,
    required this.selectedRegion,
    required this.selectedProvince,
    required this.selectedCity,
    required this.selectedStartMonth,
    required this.selectedEndMonth,
    required this.onYearChanged,
    required this.onStartMonthChanged,
    required this.onEndMonthChanged,
    required this.onRegionChanged,
    required this.onProvinceChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 7,
          runSpacing: 10,
          children: [
            MyDropdown(
              items: years,
              initialValue: selectedYear,
              hint: 'Select Year',
              icon: Icons.calendar_today,
              onChanged: onYearChanged,
            ),
            MyDropdown(
              items: months,
              initialValue: selectedStartMonth,
              hint: 'Start Month',
              icon: Icons.calendar_month,
              onChanged: onStartMonthChanged,
            ),
            MyDropdown(
              items: months,
              initialValue: selectedEndMonth,
              hint: 'End Month (optional)',
              icon: Icons.calendar_view_month,
              onChanged: onEndMonthChanged,
            ),
            MyDropdown(
              items: regions.map((r) => r['region_num'].toString()).toList(),
              initialValue: selectedRegion,
              hint: 'Select Region',
              icon: Icons.map,
              onChanged: onRegionChanged,
            ),
            MyDropdown(
              items: provinces,
              initialValue: selectedProvince,
              hint: 'Select Province',
              icon: Icons.location_city,
              onChanged: onProvinceChanged,
            ),
            MyDropdown(
              items: cities,
              initialValue: selectedCity,
              hint: 'Select City',
              icon: Icons.location_on,
              onChanged: onCityChanged,
            ),
          ],
        ),
      ),
    );
  }
}
