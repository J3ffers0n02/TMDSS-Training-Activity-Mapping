import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditDataScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String tableName;

  const EditDataScreen({
    super.key,
    required this.data,
    required this.tableName,
  });

  @override
  State<EditDataScreen> createState() => _EditDataScreenState();
}

class _EditDataScreenState extends State<EditDataScreen> {
  late TextEditingController actTitleController;
  late TextEditingController venueController;
  late TextEditingController femaleParticipantsController;
  late TextEditingController maleParticipantsController;
  late TextEditingController cityController;
  late TextEditingController provinceController;
  late TextEditingController regionNumController;
  late TextEditingController trainingTypeController;

  // Date fields as text (assuming DB stores as text)
  late TextEditingController startDateController;
  late TextEditingController endDateController;
  late TextEditingController contDayController;

  final supabase = Supabase.instance.client;

  final Color blueDost = Color(0xFF00AEF0);
  final Color blackFull = Colors.black;

  @override
  void initState() {
    super.initState();
    print('EditDataScreen received data with id: ${widget.data['id']}');

    actTitleController =
        TextEditingController(text: widget.data['act_title']?.toString() ?? '');
    venueController =
        TextEditingController(text: widget.data['venue']?.toString() ?? '');
    femaleParticipantsController = TextEditingController(
        text: widget.data['f_participant']?.toString() ?? '');
    maleParticipantsController = TextEditingController(
        text: widget.data['m_participant']?.toString() ?? '');
    cityController =
        TextEditingController(text: widget.data['city']?.toString() ?? '');
    provinceController =
        TextEditingController(text: widget.data['province']?.toString() ?? '');
    regionNumController = TextEditingController(
        text: widget.data['region_num']?.toString() ?? '');
    trainingTypeController = TextEditingController(
        text: widget.data['training_type']?.toString() ?? '');

    startDateController = TextEditingController(
        text: widget.data['start_date']?.toString() ?? '');
    endDateController =
        TextEditingController(text: widget.data['end_date']?.toString() ?? '');
    contDayController =
        TextEditingController(text: widget.data['cont_day']?.toString() ?? '');
  }

  @override
  void dispose() {
    actTitleController.dispose();
    venueController.dispose();
    femaleParticipantsController.dispose();
    maleParticipantsController.dispose();
    cityController.dispose();
    provinceController.dispose();
    regionNumController.dispose();
    trainingTypeController.dispose();

    startDateController.dispose();
    endDateController.dispose();
    contDayController.dispose();

    super.dispose();
  }

  Future<void> _updateData() async {
    try {
      final idRaw = widget.data['id'];
      print('Raw id from data: $idRaw');

      final int? idInt =
          (idRaw is int) ? idRaw : int.tryParse(idRaw.toString());
      print('Parsed id as int: $idInt');

      if (idInt == null) {
        print('Invalid ID, cannot update');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid ID, cannot update')),
        );
        return;
      }

      final Map<String, dynamic> dataToUpdate = {};

      // Compare old vs new values, add only changed
      if (actTitleController.text !=
          (widget.data['act_title']?.toString() ?? '')) {
        dataToUpdate['act_title'] = actTitleController.text;
      }
      if (venueController.text != (widget.data['venue']?.toString() ?? '')) {
        dataToUpdate['venue'] = venueController.text;
      }

      // Participants are stored as text in DB, send as String
      if (femaleParticipantsController.text !=
          (widget.data['f_participant']?.toString() ?? '')) {
        dataToUpdate['f_participant'] = femaleParticipantsController.text;
      }
      if (maleParticipantsController.text !=
          (widget.data['m_participant']?.toString() ?? '')) {
        dataToUpdate['m_participant'] = maleParticipantsController.text;
      }

      if (cityController.text != (widget.data['city']?.toString() ?? '')) {
        dataToUpdate['city'] = cityController.text;
      }
      if (provinceController.text !=
          (widget.data['province']?.toString() ?? '')) {
        dataToUpdate['province'] = provinceController.text;
      }
      if (regionNumController.text !=
          (widget.data['region_num']?.toString() ?? '')) {
        dataToUpdate['region_num'] = regionNumController.text;
      }
      if (trainingTypeController.text !=
          (widget.data['training_type']?.toString() ?? '')) {
        dataToUpdate['training_type'] = trainingTypeController.text;
      }

      // Date fields as strings
      if (startDateController.text !=
          (widget.data['start_date']?.toString() ?? '')) {
        dataToUpdate['start_date'] = startDateController.text;
      }
      if (endDateController.text !=
          (widget.data['end_date']?.toString() ?? '')) {
        dataToUpdate['end_date'] = endDateController.text;
      }
      if (contDayController.text !=
          (widget.data['cont_day']?.toString() ?? '')) {
        dataToUpdate['cont_day'] = contDayController.text;
      }

      print('Fields to update: $dataToUpdate');

      if (dataToUpdate.isEmpty) {
        print('No changes detected to update');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes detected to update')),
        );
        return;
      }

      print('Checking if record exists with id=$idInt');
      final existing = await supabase
          .from(widget.tableName)
          .select()
          .eq('id', idInt)
          .maybeSingle();
      print('Existing record fetched: $existing');

      if (existing == null) {
        print('No record found with id=$idInt');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No record found with id=$idInt')),
        );
        return;
      }

      print('Attempting update in ${widget.tableName}');
      // update returns number of affected rows (int)
      final updateCount = await supabase
          .from(widget.tableName)
          .update(dataToUpdate)
          .eq('id', idInt);

      print('Update affected rows: $updateCount');

      if (updateCount == 0) {
        throw Exception('No rows updated or ID not found');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update successful')),
      );

      Navigator.pop(context, true);
    } catch (e, st) {
      print('Update error: $e');
      print(st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update data: $e')),
      );
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Edit Data'),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Activity Title', actTitleController),
            _buildField('Venue', venueController),
            _buildField('Female Participants', femaleParticipantsController,
                keyboardType: TextInputType.number),
            _buildField('Male Participants', maleParticipantsController,
                keyboardType: TextInputType.number),
            _buildField('City', cityController),
            _buildField('Province', provinceController),
            _buildField('Region Number', regionNumController),
            _buildField('Training Type', trainingTypeController),
            _buildField('Start Date (YYYY-MM-DD)', startDateController,
                keyboardType: TextInputType.datetime),
            _buildField('End Date (YYYY-MM-DD)', endDateController,
                keyboardType: TextInputType.datetime),
            _buildField('Continuation Date (YYYY-MM-DD)', contDayController,
                keyboardType: TextInputType.datetime),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateData,
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
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],  
        ),
      ),
    );
  }
}
