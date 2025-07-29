import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImportHistoryScreen extends StatefulWidget {
  @override
  _ImportHistoryScreenState createState() => _ImportHistoryScreenState();
}

class _ImportHistoryScreenState extends State<ImportHistoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await supabase
          .from('import_history')
          .select()
          .order('imported_at', ascending: false);

      setState(() {
        history = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background
      appBar: AppBar(
        title: Text(
          'Import History',
          
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.blue[800], // light blue background
        elevation: 1,
        automaticallyImplyLeading: false, // removes back button
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(
                  child: Text(
                    'No import history found.',
                    style: TextStyle(color: Colors.black),
                  ),
                )
              : ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey),
                  itemBuilder: (context, index) {
                    final record = history[index] as Map<String, dynamic>;
                    final entries = record.entries.toList();

                    return ListTile(
                      leading: Icon(Icons.file_upload, color: Colors.black),
                      title: Text(
                        record['file_name']?.toString() ?? 'Unknown File',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entries.map<Widget>((entry) {
                          final key = entry.key;
                          var value = entry.value;

                          // Format dates if key contains 'date' and value is string
                          if (key.toLowerCase().contains('date') && value is String) {
                            value = formatDate(value);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '$key: $value',
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
