import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleGeocodingWidget extends StatefulWidget {
  const GoogleGeocodingWidget({super.key});

  @override
  State<GoogleGeocodingWidget> createState() => _GoogleGeocodingWidgetState();
}

class _GoogleGeocodingWidgetState extends State<GoogleGeocodingWidget> {
  final TextEditingController _addressController = TextEditingController();
  String? result;
  bool isLoading = false;

  final String apiKey = 'AIzaSyD4jbETUbALIDHMA0mSntf10dk1aecE-hw'; // Insert your Google API key

  Future<void> _getCoordinates() async {
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      setState(() {
        result = 'Please enter a valid address.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = null;
    });

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          setState(() {
            result = 'Latitude: ${location['lat']}, Longitude: ${location['lng']}';
          });
        } else {
          setState(() {
            result = 'No results found. Status: ${data['status']}';
          });
        }
      } else {
        setState(() {
          result = 'Failed to fetch coordinates. HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        result = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Geocoding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Enter Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCoordinates,
              child: const Text('Get Coordinates'),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (result != null) Text(result!),
          ],
        ),
      ),
    );
  }
}
