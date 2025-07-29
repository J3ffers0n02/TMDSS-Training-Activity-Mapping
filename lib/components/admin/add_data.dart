import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

extension DateTimeClamp on DateTime {
  DateTime clamp(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}

class AddDataScreen extends StatefulWidget {
  @override
  _AddDataScreenState createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final actTitleController = TextEditingController();
  final venueController = TextEditingController();
  final fParticipantsController = TextEditingController();
  final mParticipantsController = TextEditingController();
  final cityController = TextEditingController();
  final provinceController = TextEditingController();
  final regionController = TextEditingController();
  final trainingTypeController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  DateTime? contDay;

  String? selectedTable;
  String? generatedId;

  List<String> tableOptions = [];

  // Dropdown selection for region
  String? selectedRegion;
  List<Map<String, dynamic>> regions = [];

  @override
  void initState() {
    super.initState();
    fetchTrainingTables();
    fetchRegions();

    // Add listeners for real-time capitalization
    actTitleController
        .addListener(() => _capitalizeController(actTitleController));
    venueController.addListener(() => _capitalizeController(venueController));
    cityController.addListener(() => _capitalizeController(cityController));
    provinceController
        .addListener(() => _capitalizeController(provinceController));
    trainingTypeController
        .addListener(() => _capitalizeController(trainingTypeController));
  }

  // Helper function to capitalize the first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Helper function to apply capitalization to controller
  void _capitalizeController(TextEditingController controller) {
    final text = controller.text;
    final capitalized = _capitalizeFirstLetter(text);
    if (text != capitalized) {
      final selection = controller.selection;
      controller.text = capitalized;
      // Preserve cursor position, adjusting for length changes
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: selection.baseOffset.clamp(0, capitalized.length)),
      );
    }
  }

  // Helper function to extract year from table name
  int? _getTableYear() {
    if (selectedTable == null) return null;
    final yearStr = selectedTable!.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(yearStr);
  }

  Future<void> fetchTrainingTables() async {
    try {
      final data = await supabase.rpc('get_training_tables');
      if (data != null) {
        final List<dynamic> listData = List<dynamic>.from(data);
        final List<String> tables = listData.map((item) {
          if (item is Map && item.containsKey('table_name')) {
            return item['table_name'].toString();
          }
          return item.toString();
        }).toList();

        // Sort descending by year extracted from table name
        tables.sort((a, b) {
          final yearA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final yearB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return yearB.compareTo(yearA); // descending order
        });

        setState(() {
          tableOptions = tables;
        });
      }
    } catch (e) {
      print('Error fetching tables: $e');
    }
  }

  Future<void> generateCustomId(String tableName) async {
    final year = tableName.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final response = await supabase
          .from(tableName)
          .select('id')
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response['id'] == null) {
        generatedId = '${year}01';
      } else {
        final lastId = response['id'].toString();
        final lastNumber = int.tryParse(lastId.substring(year.length)) ?? 0;
        final newNumber = lastNumber + 1;
        generatedId = '$year${newNumber.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error generating ID: $e');
      generatedId = null;
    }
    setState(() {});
  }

  Future<void> _pickDate(BuildContext context, ValueChanged<DateTime> onPicked,
      {bool isStartDate = false}) async {
    final tableYear = _getTableYear();
    if (tableYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a table first')),
      );
      return;
    }

    final firstDate = DateTime(tableYear, 1, 1);
    final lastDate = DateTime(tableYear, 12, 31);
    final initialDate = isStartDate
        ? (startDate ?? DateTime.now()).clamp(firstDate, lastDate)
        : (endDate ?? contDay ?? DateTime.now()).clamp(firstDate, lastDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  bool get isSubmitEnabled {
    if (selectedTable == null ||
        generatedId == null ||
        startDate == null ||
        endDate == null ||
        _formKey.currentState?.validate() != true) {
      return false;
    }

    final tableYear = _getTableYear();
    if (tableYear == null ||
        startDate!.year != tableYear ||
        endDate!.year != tableYear ||
        (contDay != null && contDay!.year != tableYear)) {
      return false;
    }

    if (endDate!.isBefore(startDate!)) {
      return false;
    }

    if (contDay != null && contDay!.isBefore(startDate!)) {
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!isSubmitEnabled) return;

    final tableYear = _getTableYear();
    if (tableYear == null ||
        startDate!.year != tableYear ||
        endDate!.year != tableYear ||
        (contDay != null && contDay!.year != tableYear)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dates must be in the year $tableYear')),
      );
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date cannot be earlier than start date')),
      );
      return;
    }

    if (contDay != null && contDay!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Continuation date cannot be earlier than start date')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Submission'),
        content: Text('Are you sure you want to submit this record?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Submit'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final data = {
      'id': generatedId!,
      'act_title': _capitalizeFirstLetter(actTitleController.text.trim()),
      'venue': _capitalizeFirstLetter(venueController.text.trim()),
      'f_participant': int.tryParse(fParticipantsController.text) ?? 0,
      'm_participant': int.tryParse(mParticipantsController.text) ?? 0,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'city': _capitalizeFirstLetter(cityController.text.trim()),
      'province': _capitalizeFirstLetter(provinceController.text.trim()),
      'region_num': selectedRegion ??
          _capitalizeFirstLetter(regionController.text.trim()),
      'training_type':
          _capitalizeFirstLetter(trainingTypeController.text.trim()),
    };

    if (contDay != null) {
      data['cont_day'] = contDay!.toIso8601String();
    }

    try {
      await supabase.from(selectedTable!).insert(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record added successfully!')),
      );

      // 🔁 Reset everything
      setState(() {
        // Clear text controllers
        actTitleController.clear();
        venueController.clear();
        fParticipantsController.clear();
        mParticipantsController.clear();
        cityController.clear();
        provinceController.clear();
        regionController.clear();
        trainingTypeController.clear();
        generatedId = null;
        selectedTable = null;

        // Reset date pickers
        startDate = null;
        endDate = null;
        contDay = null;

        // Reset dropdown selections
        selectedRegion = null;

        // Optional: only if your UI expects an ID before next entry
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add record: $e')),
      );
    }
  }

  Future<void> fetchRegions() async {
    try {
      final response = await supabase
          .from('regions')
          .select('region_num, region_name')
          .order('region_name');

      final List<Map<String, dynamic>> fetchedRegions =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        regions = fetchedRegions;
      });
    } catch (e) {
      print('Error fetching regions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryOrange = const Color(0xFFFF9800);
    final Color dostBlue = Color(0xFF00AEF0);
    final Color fullBlack = Colors.black;

    Widget buildTwoColumnRow(Widget leftChild, Widget rightChild) {
      return Row(
        children: [
          Expanded(child: leftChild),
          SizedBox(width: 16),
          Expanded(child: rightChild),
        ],
      );
    }

    final generatedIdController =
        TextEditingController(text: generatedId ?? '');
    generatedIdController.selection = TextSelection.fromPosition(
      TextPosition(offset: generatedIdController.text.length),
    );

    return Theme(
      data: ThemeData(
        primaryColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: fullBlack,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: dostBlue),
          ),
          labelStyle: TextStyle(color: fullBlack),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            side: const BorderSide(
              color: Color(0xFF00AEF0),
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Training Data'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: ListView(
              children: [
                // Table dropdown + Generated ID
                buildTwoColumnRow(
                  DropdownButtonFormField<String>(
                    value: selectedTable,
                    decoration:
                        InputDecoration(labelText: 'Select Training Table'),
                    items: tableOptions
                        .map((table) => DropdownMenuItem(
                              value: table,
                              child: Text(table),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      if (value != selectedTable) {
                        setState(() {
                          selectedTable = value;
                          generatedId = null;
                          startDate = null;
                          endDate = null;
                          contDay = null;
                        });
                        if (value != null) await generateCustomId(value);
                      }
                    },
                    validator: (val) =>
                        val == null ? 'Please select a table' : null,
                  ),
                  TextFormField(
                    controller: generatedIdController,
                    readOnly: true,
                    decoration: InputDecoration(labelText: 'Generated ID'),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'ID not generated'
                        : null,
                  ),
                ),
                SizedBox(height: 16),

                // Activity title and Venue
                buildTwoColumnRow(
                  TextFormField(
                    controller: actTitleController,
                    decoration: InputDecoration(labelText: 'Activity Title'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: venueController,
                    decoration: InputDecoration(labelText: 'Venue'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(height: 16),

                // Female and Male Participants
                buildTwoColumnRow(
                  TextFormField(
                    controller: fParticipantsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        InputDecoration(labelText: 'Female Participants'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final n = int.tryParse(val);
                      if (n == null || n < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: mParticipantsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: 'Male Participants'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final n = int.tryParse(val);
                      if (n == null || n < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Start and End Date pickers
                buildTwoColumnRow(
                  InkWell(
                    onTap: () => _pickDate(context, (picked) {
                      setState(() => startDate = picked);
                    }, isStartDate: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        errorText: startDate == null
                            ? 'Required'
                            : (_getTableYear() != null &&
                                    startDate!.year != _getTableYear()!)
                                ? 'Must be in ${_getTableYear()}'
                                : null,
                      ),
                      child: Text(
                        startDate == null
                            ? 'Select date'
                            : DateFormat.yMd().format(startDate!),
                        style: TextStyle(
                          color: startDate == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _pickDate(context, (picked) {
                      setState(() => endDate = picked);
                    }),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        errorText: endDate == null
                            ? 'Required'
                            : (_getTableYear() != null &&
                                    endDate!.year != _getTableYear()!)
                                ? 'Must be in ${_getTableYear()}'
                                : (startDate != null &&
                                        endDate!.isBefore(startDate!))
                                    ? 'Cannot be before start date'
                                    : null,
                      ),
                      child: Text(
                        endDate == null
                            ? 'Select date'
                            : DateFormat.yMd().format(endDate!),
                        style: TextStyle(
                          color: endDate == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // cont_day (nullable)
                InkWell(
                  onTap: () => _pickDate(context, (picked) {
                    setState(() => contDay = picked);
                  }),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Continuation Day (optional)',
                      errorText: contDay != null &&
                              _getTableYear() != null &&
                              contDay!.year != _getTableYear()!
                          ? 'Must be in ${_getTableYear()}'
                          : (contDay != null &&
                                  startDate != null &&
                                  contDay!.isBefore(startDate!))
                              ? 'Cannot be before start date'
                              : null,
                    ),
                    child: Text(
                      contDay == null
                          ? 'Select date or leave empty'
                          : DateFormat.yMd().format(contDay!),
                      style: TextStyle(
                        color: contDay == null
                            ? Colors.grey.shade600
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Region dropdown
                DropdownButtonFormField<String>(
                  value: selectedRegion,
                  decoration: InputDecoration(labelText: 'Region'),
                  items: regions
                      .map<DropdownMenuItem<String>>(
                          (r) => DropdownMenuItem<String>(
                                value: r['region_num'] as String,
                                child: Text(r['region_name']),
                              ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRegion = value;
                    });
                  },
                  validator: (val) => val == null ? 'Select a region' : null,
                ),
                SizedBox(height: 16),

                // Province TextField
                TextFormField(
                  decoration: InputDecoration(labelText: 'Province'),
                  controller: provinceController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter a province' : null,
                ),
                SizedBox(height: 16),

                // City TextField
                TextFormField(
                  decoration: InputDecoration(labelText: 'City'),
                  controller: cityController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter a city' : null,
                ),
                SizedBox(height: 16),

                // Training type text field
                TextFormField(
                  controller: trainingTypeController,
                  decoration: InputDecoration(labelText: 'Training Type'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isSubmitEnabled ? _submitForm : null,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    actTitleController.dispose();
    venueController.dispose();
    fParticipantsController.dispose();
    mParticipantsController.dispose();
    cityController.dispose();
    provinceController.dispose();
    regionController.dispose();
    trainingTypeController.dispose();
    super.dispose();
  }
}
