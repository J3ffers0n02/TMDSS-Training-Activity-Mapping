import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tmdss/components/admin/import_history.dart';

class ImportDataScreen extends StatefulWidget {
  @override
  _ImportDataScreenState createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  PlatformFile? pickedFile;
  List<List<String>> previewRows = [];
  String? tableName;
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _pickFile();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null) {
      setState(() {
        pickedFile = result.files.first;
        tableName = pickedFile!.name
            .split('.')
            .first
            .replaceAll(RegExp(r'\W'), '_')
            .toLowerCase();
      });
      await _loadPreview();
    } else {
      // User canceled the picker, do NOT navigate away or pop.
      // Optionally, you can show a message or just do nothing:
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('No file selected.')),
      // );
    }
  }

  Future<void> _loadPreview() async {
    if (pickedFile == null) return;

    if (pickedFile!.extension == 'csv') {
      final csvString = String.fromCharCodes(
          pickedFile!.bytes ?? await File(pickedFile!.path!).readAsBytes());
      List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvString);
      setState(() {
        previewRows = csvTable
            .map((row) => row.map((e) => e.toString()).toList())
            .toList();
      });
    } else if (pickedFile!.extension == 'xlsx' ||
        pickedFile!.extension == 'xls') {
      var bytes =
          pickedFile!.bytes ?? await File(pickedFile!.path!).readAsBytes();
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.sheets.values.first;
      List<List<String>> rows = [];
      for (var row in sheet.rows) {
        rows.add(row.map((cell) => cell?.value.toString() ?? '').toList());
      }
      setState(() {
        previewRows = rows;
      });
    }
  }

  Future<void> _importData() async {
    if (pickedFile == null || previewRows.isEmpty || tableName == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final headers = previewRows.first.map((h) => h.trim()).toList();

      await supabase.rpc('create_table_if_not_exists', params: {
        'tbl_name': tableName,
        'columns': headers,
      });

      List<Map<String, dynamic>> rowsToInsert = [];
      for (var row in previewRows.skip(1)) {
        Map<String, dynamic> rowMap = {};
        for (int i = 0; i < headers.length; i++) {
          final key = headers[i];
          if (i < row.length) {
            var value = row[i];
            rowMap[key] = _parseValueByColumn(key, value);
          } else {
            rowMap[key] = null;
          }
        }
        rowsToInsert.add(rowMap);
      }

      final insertResponse =
          await supabase.from(tableName!).insert(rowsToInsert).select();

      if (insertResponse == null) {
        throw Exception('Failed to insert data.');
      }

      await supabase.from('import_history').insert({
        'file_name': pickedFile!.name,
        'table_name': tableName,
        'imported_by': supabase.auth.currentUser?.email ?? 'Unknown',
        'record_count': rowsToInsert.length,
      });

      _showMessage(
          'Import successful: Table "$tableName" created with ${rowsToInsert.length} records.');
    } catch (e) {
      String errorMsg = 'Import failed.';
      if (e
          .toString()
          .contains('duplicate key value violates unique constraint')) {
        errorMsg =
            'Import failed: One or more records contain an ID that already exists.';
      }
      _showMessage(errorMsg);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  dynamic _parseValueByColumn(String column, dynamic value) {
    if (value == null) return null;

    try {
      switch (column) {
        case 'id':
        case 'f_participant':
        case 'm_participant':
          return int.tryParse(value.toString());
        case 'created_at':
          return DateTime.tryParse(value.toString())?.toUtc().toIso8601String();
        case 'end_date':
        case 'start_date':
        case 'cont_day':
          return DateTime.tryParse(value.toString())
              ?.toIso8601String()
              .split('T')
              .first;
        default:
          return value.toString();
      }
    } catch (_) {
      return value.toString();
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Import File'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(icon: Icon(Icons.folder_open), onPressed: _pickFile),
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ImportHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: pickedFile == null
          ? Center(
              child: Text(
                'No file selected.',
                style: TextStyle(fontSize: 18, color: Colors.blue.shade700),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Preview of "${pickedFile!.name}" (Showing all rows):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(Colors.blue.shade200),
                        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue.shade50;
                            }
                            return null;
                          },
                        ),
                        columns: previewRows.isNotEmpty
                            ? previewRows.first
                                .map(
                                  (header) => DataColumn(
                                    label: Text(
                                      header,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                )
                                .toList()
                            : [],
                        rows: previewRows.length > 1
                            ? previewRows
                                .skip(1)
                                .map(
                                  (row) => DataRow(
                                    cells: row
                                        .map(
                                          (cell) => DataCell(
                                            Text(
                                              cell,
                                              style: TextStyle(
                                                  color:
                                                      Colors.blueGrey.shade900),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                                .toList()
                            : [],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isLoading ? null : _importData,
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Import',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
