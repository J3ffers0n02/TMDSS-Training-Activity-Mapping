// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class RegionMapUtils {
//   static final Map<String, String> regionNumToGeoJsonRegion = {
//     'I': 'Ilocos Region (Region I)',
//     'II': 'Cagayan Valley (Region II)',
//     'III': 'Central Luzon (Region III)',
//     'IV-A': 'CALABARZON (Region IV-A)',
//     'IV-B': 'MIMAROPA (Region IV-B)',
//     'V': 'Bicol Region (Region V)',
//     'VI': 'Western Visayas (Region VI)',
//     'VII': 'Central Visayas (Region VII)',
//     'VIII': 'Eastern Visayas (Region VIII)',
//     'IX': 'Zamboanga Peninsula (Region IX)',
//     'X': 'Northern Mindanao (Region X)',
//     'XI': 'Davao Region (Region XI)',
//     'XII': 'SOCCSKSARGEN (Region XII)',
//     'XIII': 'Caraga (Region XIII)',
//     'CAR': 'Cordillera Administrative Region (CAR)',
//     'NCR': 'Metropolitan Manila',
//     'BARMM': 'Autonomous Region of Muslim Mindanao (ARMM)',
//   };

//   static Future<void> zoomToRegionsExtent({
//     required GoogleMapController? controller,
//     required String regionNum,
//   }) async {
//     if (controller == null) return;

//     try {
//       final String geojson =
//           await rootBundle.loadString('assets/geojson/adm1_ph.json');
//       final Map<String, dynamic> data = jsonDecode(geojson);

//       final features = data['features'];
//       if (features.isEmpty) return;

//       // Map the region_num to the GeoJSON-compatible name
//       final geoJsonRegionName = regionNumToGeoJsonRegion[regionNum];
//       if (geoJsonRegionName == null) {
//         print('Region number $regionNum not mapped to a GeoJSON region');
//         return;
//       }
//       print('Mapped region: $regionNum -> $geoJsonRegionName');

//       // Find the feature matching the mapped region name
//       final regionFeature = features.firstWhere(
//         (feature) => feature['properties']['REGION'] == geoJsonRegionName,
//         orElse: () => null,
//       );

//       if (regionFeature == null) {
//         print('Region $geoJsonRegionName not found in GeoJSON');
//         return;
//       }

//       final geometry = regionFeature['geometry'];
//       if (geometry == null) return;

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
//         return;
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
//         final bounds = LatLngBounds(
//           southwest: LatLng(minLat, minLng),
//           northeast: LatLng(maxLat, maxLng),
//         );

//         // Step 1: Start zoomed in to the region's bounds
//         await controller.animateCamera(
//           CameraUpdate.newLatLngBounds(bounds, 50),
//           duration: const Duration(milliseconds: 400),
//         );

//         // Step 2: Wait briefly to show the zoomed-in view
//         await Future.delayed(const Duration(milliseconds: 200));
//       }
//     } catch (e) {
//       print('Error zooming to region $regionNum: $e');
//     }
//   }
// }
