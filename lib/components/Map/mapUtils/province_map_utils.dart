// import 'dart:convert';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class ProvinceMapUtils {
//   static final Map<String, List<LatLng>> provinceBounds = {};

//   static void initializeProvinceBounds(String geoJsonString) {
//     final geoJson = jsonDecode(geoJsonString) as Map<String, dynamic>;
//     final features = geoJson['features'] as List<dynamic>;

//     for (var feature in features) {
//       final properties = feature['properties'] as Map<String, dynamic>;
//       final regionCode = properties['GID_0'];
//       final provinceName = properties['NAME_1'];
//       final geometry = feature['geometry'] as Map<String, dynamic>;
//       final coordinates = geometry['coordinates'] as List<dynamic>;

//       List<LatLng> bounds = [];
//       for (var coordList in coordinates) {
//         for (var coord in coordList[0]) { // Assuming MultiPolygon with first polygon
//           bounds.add(LatLng(coord[1] as double, coord[0] as double));
//         }
//       }
//       provinceBounds['$regionCode-$provinceName'] = bounds;
//     }
//   }

//   static LatLngBounds getProvinceBounds(String regionCode, String provinceName) {
//     final key = '$regionCode-$provinceName';
//     final bounds = provinceBounds[key] ?? [];
//     if (bounds.isEmpty) return LatLngBounds();
//     double minLat = bounds.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
//     double maxLat = bounds.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
//     double minLng = bounds.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
//     double maxLng = bounds.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
//     return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
//   }

//   static void zoomToProvince(MapController mapController, String regionCode, String provinceName) {
//     final bounds = getProvinceBounds(regionCode, provinceName);
//     if (bounds.isNotEmpty) {
//       mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(20.0)));
//     }
//   }
// }