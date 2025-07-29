// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class PhilippinesMapUtils {
//   static Future<LatLng?> computePhilippinesCenter() async {
//     try {
//       final String geojson =
//           await rootBundle.loadString('assets/geojson/adm0_ph.json');
//       final Map<String, dynamic> data = jsonDecode(geojson);

//       final features = data['features'];
//       if (features.isEmpty) return null;

//       final geometry = features[0]['geometry'];
//       if (geometry == null) return null;

//       List coordinates = [];

//       if (geometry['type'] == 'Polygon') {
//         coordinates = geometry['coordinates'][0];
//       } else if (geometry['type'] == 'MultiPolygon') {
//         for (var polygon in geometry['coordinates']) {
//           for (var ring in polygon) {
//             coordinates.addAll(ring);
//           }
//         }
//       } else {
//         return null; // Not a supported geometry type
//       }

//       double? minLat, minLng, maxLat, maxLng;

//       for (var coord in coordinates) {
//         final double lng = coord[0].toDouble();
//         final double lat = coord[1].toDouble();

//         if (minLat == null || lat < minLat) minLat = lat;
//         if (maxLat == null || lat > maxLat) maxLat = lat;
//         if (minLng == null || lng < minLng) minLng = lng;
//         if (maxLng == null || lng > maxLng) maxLng = lng;
//       }

//       if (minLat != null &&
//           maxLat != null &&
//           minLng != null &&
//           maxLng != null) {
//         final centerLat = (minLat + maxLat) / 2;
//         final centerLng = (minLng + maxLng) / 2;
//         return LatLng(centerLat, centerLng);
//       }
//     } catch (e) {
//       print('Error computing center: $e');
//     }
//     return null;
//   }

//   static Future<void> zoomToPhilippinesExtent({
//     required GoogleMapController? controller,
//     required LatLng? initialCenter,
//   }) async {
//     if (controller == null || initialCenter == null) return;

//     final String geojson =
//         await rootBundle.loadString('assets/geojson/adm0_ph.json');
//     final Map<String, dynamic> data = jsonDecode(geojson);

//     final features = data['features'];
//     if (features.isEmpty) return;

//     final geometry = features[0]['geometry'];
//     if (geometry == null) return;

//     List coordinates = [];
//     if (geometry['type'] == 'Polygon') {
//       coordinates = geometry['coordinates'][0];
//     } else if (geometry['type'] == 'MultiPolygon') {
//       for (var polygon in geometry['coordinates']) {
//         for (var ring in polygon) {
//           coordinates.addAll(ring);
//         }
//       }
//     } else {
//       return;
//     }

//     double? minLat, minLng, maxLat, maxLng;
//     for (var coord in coordinates) {
//       final double lng = coord[0].toDouble();
//       final double lat = coord[1].toDouble();

//       if (minLat == null || lat < minLat) minLat = lat;
//       if (maxLat == null || lat > maxLat) maxLat = lat;
//       if (minLng == null || lng < minLng) minLng = lng;
//       if (maxLng == null || lng > maxLng) maxLng = lng;
//     }

//     if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
//       final bounds = LatLngBounds(
//         southwest: LatLng(minLat, minLng),
//         northeast: LatLng(maxLat, maxLng),
//       );

//       // Step 1: Start with a slightly broader view (e.g., zoom level 4.0) at the center
//       await controller.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: initialCenter,
//             zoom: 4.0, // Starting from a tad bit broader
//           ),
//         ),
//         duration: const Duration(milliseconds: 400),
//       );

//       // Step 2: Wait briefly (200ms) to show the broader view
//       await Future.delayed(const Duration(milliseconds: 200));

//       // Step 3: Zoom in to the initial zoom level (5.8) as an intermediate step
//       await controller.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: initialCenter,
//             zoom: 5.8, // Match the initialCameraPosition zoom
//           ),
//         ),
//         duration: const Duration(milliseconds: 400),
//       );

//       // Step 4: Zoom out slightly to the full Philippines bounds
//       await controller.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 50),
//         duration: const Duration(milliseconds: 600),
//       );
//     }
//   }
// }