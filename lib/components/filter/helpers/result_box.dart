import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tmdss/components/filter/helpers/result_tile.dart';

class ResultBox extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final bool shouldShow;
  final bool isLoading;
  final String tableName;
  final void Function(Map<String, dynamic> training) onTrainingSelected;
  final VoidCallback onBackToList;

  const ResultBox({
    super.key,
    required this.results,
    required this.shouldShow,
    this.isLoading = false,
    this.tableName = 'training_data',
    required this.onTrainingSelected, // 👈
    required this.onBackToList,
  });

  @override
  State<ResultBox> createState() => _ResultBoxState();
}

class _ResultBoxState extends State<ResultBox> {
  Map<String, dynamic>? selectedTraining;
  bool isFetchingDetails = false;

  @override
  void didUpdateWidget(ResultBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results != oldWidget.results && selectedTraining != null) {
      setState(() {
        selectedTraining = null;
        isFetchingDetails = false;
      });
    }
  }

  DateTime? parseDate(String? dateStr) {
    try {
      return DateTime.parse(dateStr ?? '');
    } catch (_) {
      return null;
    }
  }

  void _onTrainingTapped(Map<String, dynamic> training) async {
    setState(() {
      isFetchingDetails = true;
      selectedTraining = null;
    });

    try {
      final actTitle = training['act_title']?.toString();
      final startDateStr = training['start_date']?.toString();
      final venue = training['venue']?.toString();

      if (actTitle == null || startDateStr == null || venue == null) {
        throw Exception('Missing necessary fields to fetch training details.');
      }

      // Parse date string to extract year for table name
      DateTime? startDate = parseDate(startDateStr);
      if (startDate == null) throw Exception('Unrecognized start date format.');

      final year = startDate.year;
      final tableName = 'training_info_$year';
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(tableName)
          .select(
            'act_title, venue, start_date, end_date, m_participant, f_participant, cont_day, city, province, region_num, training_type',
          )
          .eq('act_title', actTitle)
          .eq('start_date', startDateStr)
          .eq('venue', venue)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        throw Exception('Training not found in $tableName');
      }

      setState(() {
        selectedTraining = response;
        isFetchingDetails = false;
      });
      widget.onTrainingSelected(response);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isFetchingDetails = false;
        selectedTraining = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load training details: $e')),
      );
    }
  }

  void _onBackPressed() {
    setState(() {
      selectedTraining = null;
      isFetchingDetails = false;
    });
    widget.onBackToList();
  }

  String getFriendlyLabel(String key) {
    switch (key) {
      case 'act_title':
        return 'Activity Title';
      case 'venue':
        return 'Venue';
      case 'm_participant':
        return 'Male Participants';
      case 'f_participant':
        return 'Female Participants';
      case 'start_date':
        return 'Start Date';
      case 'end_date':
        return 'End Date';
      case 'cont_day':
        return 'Continuation Day';
      case 'city':
        return 'City';
      case 'province':
        return 'Province';
      case 'region_num':
        return 'Region';
      case 'training_type':
        return 'Training Type';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: Text("No results found.")),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDetailsView() {
    if (isFetchingDetails) return _buildLoadingIndicator();
    if (selectedTraining == null) return _buildEmptyState();

    final fields = selectedTraining!.entries.toList();

    final participantWidgets = <Widget>[
      _buildFieldWidget(
          'Male Participants', selectedTraining!['m_participant']),
      _buildFieldWidget(
          'Female Participants', selectedTraining!['f_participant']),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: _onBackPressed,
                tooltip: 'Back to list',
              ),
              const Text(
                'Training Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Container(
                padding:EdgeInsets.all(20),
                decoration: BoxDecoration(
                  
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Color(0xFF00AEF0), width: 1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var entry in fields)
                      if (entry.key != 'm_participant' &&
                          entry.key != 'f_participant')
                        _buildFieldWidget(
                            getFriendlyLabel(entry.key), entry.value),
                    ...participantWidgets,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldWidget(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.results.length,
      itemBuilder: (context, index) {
        final item = widget.results[index];
        final startDate = parseDate(item['start_date']) ?? DateTime(2000);
        final endDate = parseDate(item['end_date']) ?? DateTime(2000);

        return GestureDetector(
          onTap: () => _onTrainingTapped(item),
          child: ResultTile(
            title: item['act_title'].toString().trim(),
            venue: item['venue'].toString().trim(),
            startDate: startDate,
            endDate: endDate,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldShow) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            widget.results.isEmpty && selectedTraining == null ? 80 : 450,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: widget.isLoading
          ? _buildLoadingIndicator()
          : widget.results.isEmpty && selectedTraining == null
              ? _buildEmptyState()
              : selectedTraining != null || isFetchingDetails
                  ? _buildDetailsView()
                  : _buildListView(),
    );
  }
}
