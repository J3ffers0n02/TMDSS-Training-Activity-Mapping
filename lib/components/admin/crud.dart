import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tmdss/components/admin/add_data.dart';
import 'package:tmdss/components/admin/edit_data.dart';
import 'package:tmdss/components/admin/import_data.dart';
import 'package:intl/intl.dart';

class FileManagementAdminPage extends StatefulWidget {
  const FileManagementAdminPage({super.key});

  @override
  _FileManagementAdminPageState createState() =>
      _FileManagementAdminPageState();
}

class _FileManagementAdminPageState extends State<FileManagementAdminPage> {
  final Color primaryOrange = const Color(0xFFFF9800);
  final Color dostBlue = Color(0xFF00AEF0);
  final Color fullBlack = Colors.black;

  List<String> availableYears = [];
  String? selectedYear;

  List<Map<String, dynamic>> tableData = [];

  @override
  void initState() {
    super.initState();
    fetchTrainingTables().then((tables) {
      setState(() {
        availableYears = tables;
        if (availableYears.isNotEmpty) {
          selectedYear = availableYears[0];
          fetchTableData(selectedYear!);
        }
      });
    });
  }

  // Real DB call to fetch all training tables like 'training_info_YYYY'
  Future<List<String>> fetchTrainingTables() async {
    try {
      // Using rpc() with typed response: it returns List<dynamic> directly or throws
      final result =
          await Supabase.instance.client.rpc('get_training_tables').select();

      if (result is List) {
        List<String> years = [];

        for (var item in result) {
          if (item is Map && item.containsKey('table_name')) {
            final tableName = item['table_name'].toString();
            final yearMatch =
                RegExp(r'training_info_(\d{4})').firstMatch(tableName);
            if (yearMatch != null) {
              years.add(yearMatch.group(1)!);
            }
          }
        }

        years.sort((a, b) => b.compareTo(a)); // Sort descending by year
        return years;
      } else {
        return [];
      }
    } catch (e) {
      print('Exception fetching tables: $e');
      return [];
    }
  }

  // Real DB call to fetch all data from the selected training_info_YYYY table
  Future<void> fetchTableData(String year) async {
    final tableName = 'training_info_$year';

    try {
      final data = await Supabase.instance.client
          .from(tableName)
          .select()
          .then((value) => value as List<dynamic>);

      if (!mounted) return; // Check if widget is still mounted

      if (data.isNotEmpty) {
        setState(() {
          tableData = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() {
          tableData = [];
        });
      }
    } catch (e) {
      print('Exception fetching table data: $e');
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        tableData = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 4,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.folder, color: Color(0xFF00AEF0), size: 26),
            const SizedBox(width: 12),
            Text(
              'File Management',
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown + Buttons Row
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    hint: Text(
                      'Select Year',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 16),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: dostBlue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: dostBlue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).colorScheme.tertiary),
                    isExpanded:
                        true, // Ensures the dropdown menu width matches the field
                    dropdownColor: fullBlack,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 16),
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12)), // Match bottom corners
                    items: availableYears.map((String year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(
                          'training_info_$year',
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inverseSurface,
                              fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedYear = newValue;
                        });
                        fetchTableData(newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddDataScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    side: const BorderSide(
                      color: Color(0xFF00AEF0),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Add Record",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ImportDataScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    side: const BorderSide(
                      color: Color(0xFF00AEF0),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Import",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const Text(
              "Training Records",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.4,
              ),
            ),
            const Divider(
              color: Colors.black38,
              thickness: 1.2,
              height: 28,
            ),
            Expanded(
              child: tableData.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available for the selected year',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tableData.length,
                      itemBuilder: (context, index) {
                        final record = tableData[index];
                        // Parse and format the start_date
                        String formattedDate = 'Unknown';
                        if (record['start_date'] != null) {
                          try {
                            DateTime date =
                                DateTime.parse(record['start_date']);
                            formattedDate =
                                DateFormat('yyyy MMM dd').format(date);
                          } catch (e) {
                            print('Error parsing date: $e');
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: fullBlack,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: dostBlue, width: 3),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record['act_title'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                formattedDate, // Use the formatted date
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface,
                                    fontSize: 14),
                              ),
                              const SizedBox(width: 28),
                              ElevatedButton(
                                onPressed: () async {
                                  final edited = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditDataScreen(
                                        data: record,
                                        tableName:
                                            'training_info_$selectedYear',
                                      ),
                                    ),
                                  );

                                  if (edited == true) {
                                    await fetchTableData(
                                        selectedYear!); // Refresh the data
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: fullBlack,
                                  side: BorderSide(
                                    color: dostBlue,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12),
                                  elevation: 3,
                                  shadowColor: dostBlue,
                                ),
                                child: Text(
                                  "Edit",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                      fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 16),
                              TextButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Confirm Deletion"),
                                      content: Text(
                                        "Are you sure you want to delete the activity titled:\n\n“${record['act_title']}”?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await Supabase.instance.client
                                          .from('training_info_$selectedYear')
                                          .delete()
                                          .eq('id', record['id']);

                                      setState(() {
                                        tableData.removeAt(index);
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Deleted: ${record['act_title']}")),
                                      );
                                    } catch (e) {
                                      print('Error deleting record: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Failed to delete record")),
                                      );
                                    }
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12),
                                ),
                                child: Text("Delete",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
