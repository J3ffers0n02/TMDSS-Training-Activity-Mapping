import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tmdss/components/Map/overlays/filter_dropdowns.dart';
import 'package:tmdss/components/Map/overlays/search_and_results.dart';
import 'package:tmdss/components/filter/funcs/filter_functions.dart';
import 'package:tmdss/components/filter/var/filter_variables.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String? selectedYear;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;
  String? selectedStartMonth;
  String? selectedEndMonth;

  List<Map<String, dynamic>> regions = [];
  List<String> provinces = [];
  List<String> cities = [];
  List<Map<String, dynamic>> trainingData = [];

  bool isProvincesLoading = false;
  bool isCitiesLoading = false;
  bool isLoading = false;
  bool isMapLoading = true;
  GoogleMapController? _mapController;
  LatLng? initialCenter;
  late Set<Marker> _originalMarkers = {};

  // Add variables for markers and polygons
  Set<Marker> _markers = {};
  final Map<String, LatLng> _geocodeCache = {};
  final Set<Polygon> _polygons = {};
  String? _activeMarkerLoadId;

  bool get hasSelectedAnyFilter =>
      selectedYear != null ||
      selectedRegion != null ||
      selectedProvince != null ||
      selectedCity != null ||
      selectedStartMonth != null ||
      selectedEndMonth != null;

  final Map<String, String> regionNumToGeoJsonRegion = {
    'I': 'Ilocos Region (Region I)',
    'II': 'Cagayan Valley (Region II)',
    'III': 'Central Luzon (Region III)',
    'IV-A': 'CALABARZON (Region IV-A)',
    'IV-B': 'MIMAROPA (Region IV-B)',
    'V': 'Bicol Region (Region V)',
    'VI': 'Western Visayas (Region VI)',
    'VII': 'Central Visayas (Region VII)',
    'VIII': 'Eastern Visayas (Region VIII)',
    'IX': 'Zamboanga Peninsula (Region IX)',
    'X': 'Northern Mindanao (Region X)',
    'XI': 'Davao Region (Region XI)',
    'XII': 'SOCCSKSARGEN (Region XII)',
    'XIII': 'Caraga (Region XIII)',
    'CAR': 'Cordillera Administrative Region (CAR)',
    'NCR': 'Metropolitan Manila',
    'BARMM': 'Autonomous Region of Muslim Mindanao (ARMM)',
  };

  final Set<Marker> markers2025 = {
    Marker(
      markerId: MarkerId('FPRDI'),
      position: LatLng(14.156961, 121.235493), // Update with actual LatLng
    ),
  };

  @override
  void initState() {
    super.initState();
    initAsync();
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<LatLng?> fetchLatLngFromAddress(String address) async {
    if (_geocodeCache.containsKey(address)) {
      return _geocodeCache[address]; // ✅ Use cached location
    }

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final latLng = LatLng(location['lat'], location['lng']);
          _geocodeCache[address] = latLng; // ✅ Cache result
          return latLng;
        } else {
          print('Geocoding failed: ${data['status']} for $address');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching geocode: $e');
    }
    return null;
  }

  Future<void> loadTrainingMarkers(
      List<Map<String, dynamic>> trainings, String loadId) async {
    _markers.clear();
    _originalMarkers = {};

    for (var training in trainings) {
      if (_activeMarkerLoadId != loadId) {
        print('Cancelled marker loading: new filter selected');
        return;
      }

      final String venue = training['venue'] ?? '';
      final String city = training['city'] ?? '';
      final String province = training['province'] ?? '';

      if (venue.isEmpty) continue;

      final String address = '$venue, $city, $province';
      final LatLng? location = await fetchLatLngFromAddress(address);

      if (location != null) {
        final marker = Marker(
          markerId: MarkerId('training_${venue}_${city}_${province}'),
          position: location,
          infoWindow: InfoWindow(title: venue, snippet: '$city, $province'),
        );

        if (_activeMarkerLoadId != loadId) return;

        setState(() {
          _markers.add(marker);
        });

        _originalMarkers.add(marker);
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        print('Failed to geocode: $address');
      }
    }
  }

  Future<LatLng?> computePhilippinesCenter() async {
    try {
      final String geojson =
          await rootBundle.loadString('assets/geojson/adm0_ph.json');
      final Map<String, dynamic> data = jsonDecode(geojson);

      final features = data['features'];
      if (features.isEmpty) return null;

      final geometry = features[0]['geometry'];
      if (geometry == null) return null;

      List coordinates = [];

      if (geometry['type'] == 'Polygon') {
        coordinates = geometry['coordinates'][0];
      } else if (geometry['type'] == 'MultiPolygon') {
        for (var polygon in geometry['coordinates']) {
          for (var ring in polygon) {
            coordinates.addAll(ring);
          }
        }
      } else {
        return null;
      }

      double? minLat, minLng, maxLat, maxLng;

      for (var coord in coordinates) {
        final double lng = coord[0].toDouble();
        final double lat = coord[1].toDouble();

        if (minLat == null || lat < minLat) minLat = lat;
        if (maxLat == null || lat > maxLat) maxLat = lat;
        if (minLng == null || lng < minLng) minLng = lng;
        if (maxLng == null || lng > maxLng) maxLng = lng;
      }

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;
        return LatLng(centerLat, centerLng);
      }
    } catch (e) {
      print('Error computing center: $e');
    }
    return null;
  }

  Future<void> zoomToPhilippinesExtent() async {
    if (_mapController == null || initialCenter == null) return;

    final String geojson =
        await rootBundle.loadString('assets/geojson/adm0_ph.json');
    final Map<String, dynamic> data = jsonDecode(geojson);

    final features = data['features'];
    if (features.isEmpty) return;

    final geometry = features[0]['geometry'];
    if (geometry == null) return;

    List coordinates = [];
    if (geometry['type'] == 'Polygon') {
      coordinates = geometry['coordinates'][0];
    } else if (geometry['type'] == 'MultiPolygon') {
      for (var polygon in geometry['coordinates']) {
        for (var ring in polygon) {
          coordinates.addAll(ring);
        }
      }
    } else {
      return;
    }

    double? minLat, minLng, maxLat, maxLng;
    for (var coord in coordinates) {
      final double lng = coord[0].toDouble();
      final double lat = coord[1].toDouble();

      if (minLat == null || lat < minLat) minLat = lat;
      if (maxLat == null || lat > maxLat) maxLat = lat;
      if (minLng == null || lng < minLng) minLng = lng;
      if (maxLng == null || lng > maxLng) maxLng = lng;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: initialCenter!,
            zoom: 4.0,
          ),
        ),
        duration: const Duration(milliseconds: 400),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: initialCenter!,
            zoom: 5.8,
          ),
        ),
        duration: const Duration(milliseconds: 400),
      );

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
        duration: const Duration(milliseconds: 600),
      );

      // Clear markers and polygons when zooming to Philippines
      setState(() {
        _markers.clear();
        _polygons.clear();
      });
    }
  }

  void clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

  void restoreAllMarkers() {
    setState(() {
      _markers.clear();
      _markers.addAll(_originalMarkers);
    });

    // Optional: Zoom out a bit after restoring
    _mapController?.animateCamera(
      CameraUpdate.zoomTo(6), // Adjust zoom level as you want
    );
  }

  Future<void> zoomToTraining(Map<String, dynamic> training) async {
    final String venue = training['venue'] ?? '';
    final String city = training['city'] ?? '';
    final String province = training['province'] ?? '';

    if (venue.isEmpty) return;

    final String address = '$venue, $city, $province';
    final LatLng? location = await fetchLatLngFromAddress(address);

    if (location != null) {
      // Cleaned lowercase strings for better comparison
      final String cleanedVenue = venue.trim().toLowerCase();
      final String cleanedCity = city.trim().toLowerCase();
      final String cleanedProvince = province.trim().toLowerCase();

      // If the venue contains ONLY the city/province names, we assume it's generic
      final bool isGenericVenue = cleanedVenue == cleanedCity ||
          cleanedVenue == cleanedProvince ||
          cleanedVenue == '$cleanedCity, $cleanedProvince' ||
          cleanedVenue == '$cleanedProvince, $cleanedCity';

      final double zoomLevel = isGenericVenue ? 11 : 17;

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, zoomLevel),
      );

      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId('selected_training'),
            position: location,
            infoWindow: InfoWindow(title: venue, snippet: '$city, $province'),
          ),
        };
      });
    } else {
      print('Zoom failed — Could not get geocode for $address');
    }
  }

  Future<void> zoomToRegionsExtent(String regionNum) async {
    if (_mapController == null) return;

    try {
      final String geojson =
          await rootBundle.loadString('assets/geojson/adm1_ph.json');
      final Map<String, dynamic> data = jsonDecode(geojson);

      final features = data['features'];
      if (features.isEmpty) {
        await zoomToPhilippinesExtent();
        return;
      }

      final geoJsonRegionName = regionNumToGeoJsonRegion[regionNum];
      if (geoJsonRegionName == null) {
        print('Region number $regionNum not mapped to a GeoJSON region');
        await zoomToPhilippinesExtent();
        return;
      }
      print('Mapped region: $regionNum -> $geoJsonRegionName');

      final regionFeature = features.firstWhere(
        (feature) => feature['properties']['REGION'] == geoJsonRegionName,
        orElse: () => null,
      );

      if (regionFeature == null) {
        print('Region $geoJsonRegionName not found in GeoJSON');
        await zoomToPhilippinesExtent();
        return;
      }

      final geometry = regionFeature['geometry'];
      if (geometry == null) {
        await zoomToPhilippinesExtent();
        return;
      }

      List coordinates = [];
      if (geometry['type'] == 'Polygon') {
        coordinates = geometry['coordinates'][0];
      } else if (geometry['type'] == 'MultiPolygon') {
        for (var polygon in geometry['coordinates']) {
          for (var ring in polygon) {
            coordinates.addAll(ring);
          }
        }
      } else {
        await zoomToPhilippinesExtent();
        return;
      }

      double? minLat, minLng, maxLat, maxLng;
      for (var coord in coordinates) {
        final double lng = coord[0].toDouble();
        final double lat = coord[1].toDouble();

        if (minLat == null || lat < minLat) minLat = lat;
        if (maxLat == null || lat > maxLat) maxLat = lat;
        if (minLng == null || lng < minLng) minLng = lng;
        if (maxLng == null || lng > maxLng) maxLng = lng;
      }

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;
        final center = LatLng(centerLat, centerLng);

        setState(() {
          _markers.clear();
          _polygons.clear();
          // Add polygon for region outline
          if (geometry['type'] == 'Polygon') {
            _polygons.add(
              Polygon(
                polygonId: PolygonId('region_$regionNum'),
                points: geometry['coordinates'][0]
                    .map<LatLng>((coord) =>
                        LatLng(coord[1].toDouble(), coord[0].toDouble()))
                    .toList(),
                strokeColor: Colors.yellowAccent,
                strokeWidth: 2,
                fillColor: Colors.yellow.withOpacity(0.2),
              ),
            );
          } else if (geometry['type'] == 'MultiPolygon') {
            int polygonIndex = 0;
            for (var polygon in geometry['coordinates']) {
              _polygons.add(
                Polygon(
                  polygonId: PolygonId('region_${regionNum}_$polygonIndex'),
                  points: polygon[0]
                      .map<LatLng>((coord) =>
                          LatLng(coord[1].toDouble(), coord[0].toDouble()))
                      .toList(),
                  strokeColor: Colors.yellowAccent,
                  strokeWidth: 2,
                  fillColor: Colors.yellow.withOpacity(0.2),
                ),
              );
              polygonIndex++;
            }
          }
        });

        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: center,
              zoom: 6.5,
            ),
          ),
          duration: const Duration(milliseconds: 400),
        );

        await Future.delayed(const Duration(milliseconds: 200));

        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
          duration: const Duration(milliseconds: 600),
        );
      } else {
        await zoomToPhilippinesExtent();
      }
    } catch (e) {
      print('Error zooming to region $regionNum: $e');
      await zoomToPhilippinesExtent();
    }
  }

  Future<void> zoomToProvinceExtent(String provinceName) async {
    if (_mapController == null) return;

    try {
      final String geojson =
          await rootBundle.loadString('assets/geojson/adm2_ph.json');
      final Map<String, dynamic> data = jsonDecode(geojson);

      final features = data['features'];
      if (features.isEmpty) {
        print('No features found in adm2_ph.json');
        await zoomToPhilippinesExtent();
        return;
      }

      String normalizedProvinceName =
          provinceName.replaceAll(' ', '').trim().toLowerCase();

      final Map<String, String> provinceMappings = {
        'metromanila': 'metropolitanmanila',
        'lanaodelsur': 'lanaodelsur',
      };

      normalizedProvinceName =
          provinceMappings[normalizedProvinceName] ?? normalizedProvinceName;

      final provinceFeature = features.firstWhere(
        (feature) {
          final name = feature['properties']['NAME_1'] as String? ?? '';
          return name.replaceAll(' ', '').trim().toLowerCase() ==
              normalizedProvinceName;
        },
        orElse: () => null,
      );

      if (provinceFeature == null) {
        print('Province $provinceName not found in adm2_ph.json');
        await zoomToPhilippinesExtent();
        return;
      }

      final geometry = provinceFeature['geometry'];
      if (geometry == null) {
        print('No geometry found for province $provinceName');
        return;
      }

      List coordinates = [];
      if (geometry['type'] == 'Polygon') {
        coordinates = geometry['coordinates'][0];
      } else if (geometry['type'] == 'MultiPolygon') {
        for (var polygon in geometry['coordinates']) {
          for (var ring in polygon) {
            coordinates.addAll(ring);
          }
        }
      } else {
        print('Unsupported geometry type for province $provinceName');
        return;
      }

      double? minLat, minLng, maxLat, maxLng;
      for (var coord in coordinates) {
        final double lng = coord[0].toDouble();
        final double lat = coord[1].toDouble();

        if (minLat == null || lat < minLat) minLat = lat;
        if (maxLat == null || lat > maxLat) maxLat = lat;
        if (minLng == null || lng < minLng) minLng = lng;
        if (maxLng == null || lng > maxLng) maxLng = lng;
      }

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;
        final center = LatLng(centerLat, centerLng);

        setState(() {
          _markers.clear();
          _polygons.clear();
          // Add polygon for province outline
          if (geometry['type'] == 'Polygon') {
            _polygons.add(
              Polygon(
                polygonId: PolygonId('province_$provinceName'),
                points: geometry['coordinates'][0]
                    .map<LatLng>((coord) =>
                        LatLng(coord[1].toDouble(), coord[0].toDouble()))
                    .toList(),
                strokeColor: Colors.yellowAccent,
                strokeWidth: 2,
                fillColor: Colors.yellow.withOpacity(0.2),
              ),
            );
          } else if (geometry['type'] == 'MultiPolygon') {
            int polygonIndex = 0;
            for (var polygon in geometry['coordinates']) {
              _polygons.add(
                Polygon(
                  polygonId:
                      PolygonId('province_${provinceName}_$polygonIndex'),
                  points: polygon[0]
                      .map<LatLng>((coord) =>
                          LatLng(coord[1].toDouble(), coord[0].toDouble()))
                      .toList(),
                  strokeColor: Colors.yellowAccent,
                  strokeWidth: 2,
                  fillColor: Colors.yellow.withOpacity(0.2),
                ),
              );
              polygonIndex++;
            }
          }
        });

        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: center,
              zoom: 6.5,
            ),
          ),
          duration: const Duration(milliseconds: 400),
        );

        await Future.delayed(const Duration(milliseconds: 200));

        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
          duration: const Duration(milliseconds: 600),
        );
      } else {
        print('Invalid bounds for province $provinceName');
        await zoomToPhilippinesExtent();
      }
    } catch (e) {
      print('Error zooming to province $provinceName: $e');
      await zoomToPhilippinesExtent();
    }
  }

  Future<void> zoomToCityExtent(String provinceName, String cityName) async {
    if (_mapController == null) return;

    try {
      final String geojson =
          await rootBundle.loadString('assets/geojson/adm3_ph.json');
      final Map<String, dynamic> data = jsonDecode(geojson);
      final features = data['features'];

      double? minLat, minLng, maxLat, maxLng;
      bool cityFound = false;

      print('Searching for city: $cityName in province: $provinceName');

      // Normalize input names by removing spaces and converting to lowercase
      final normalizedProvince = provinceName.replaceAll(' ', '').toLowerCase();
      final normalizedCity = cityName.replaceAll(' ', '').toLowerCase();

      for (var feature in features) {
        final properties = feature['properties'];
        final currentProvince = properties['NAME_1'] as String? ?? '';
        final currentCity = properties['NAME_2'] as String? ?? '';
        final geometry = feature['geometry'];

        // Normalize feature names
        final normalizedCurrentProvince =
            currentProvince.replaceAll(' ', '').toLowerCase();
        final normalizedCurrentCity =
            currentCity.replaceAll(' ', '').toLowerCase();

        print('Checking: Province=$currentProvince, City=$currentCity');
        print(
            'Comparing: Normalized Province=$normalizedCurrentProvince with $normalizedProvince, Normalized City=$normalizedCurrentCity with $normalizedCity');

        if (normalizedCurrentProvince == normalizedProvince &&
            normalizedCurrentCity == normalizedCity &&
            geometry != null &&
            geometry['type'] == 'MultiPolygon') {
          cityFound = true;
          final coordinates = geometry['coordinates'];

          for (var polygon in coordinates) {
            for (var ring in polygon) {
              for (var coord in ring) {
                final double lng = coord[0].toDouble();
                final double lat = coord[1].toDouble();

                if (minLat == null || lat < minLat) minLat = lat;
                if (maxLat == null || lat > maxLat) maxLat = lat;
                if (minLng == null || lng < minLng) minLng = lng;
                if (maxLng == null || lng > maxLng) maxLng = lng;
              }
            }
          }
          break;
        }
      }

      if (!cityFound) {
        print('City $cityName not found in $provinceName');
        await zoomToProvinceExtent(provinceName);
        return;
      }

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;
        final center = LatLng(centerLat, centerLng);

        setState(() {
          _markers.clear();
          _polygons.clear();
          // Add polygon for city outline
          final cityFeature = features.firstWhere(
            (feature) =>
                feature['properties']['NAME_1']
                        .replaceAll(' ', '')
                        .toLowerCase() ==
                    normalizedProvince &&
                feature['properties']['NAME_2']
                        .replaceAll(' ', '')
                        .toLowerCase() ==
                    normalizedCity,
          );
          final geometry = cityFeature['geometry'];
          if (geometry['type'] == 'MultiPolygon') {
            int polygonIndex = 0;
            for (var polygon in geometry['coordinates']) {
              _polygons.add(
                Polygon(
                  polygonId: PolygonId(
                      'city_${provinceName}_${cityName}_$polygonIndex'),
                  points: polygon[0]
                      .map<LatLng>((coord) =>
                          LatLng(coord[1].toDouble(), coord[0].toDouble()))
                      .toList(),
                  strokeColor: Colors.yellowAccent,
                  strokeWidth: 2,
                  fillColor: Colors.yellow.withOpacity(0.2),
                ),
              );
              polygonIndex++;
            }
          }
        });

        print('Zooming to city $cityName at center: $center');

        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: center,
              zoom: 10.0,
            ),
          ),
          duration: const Duration(milliseconds: 400),
        );

        await Future.delayed(const Duration(milliseconds: 200));

        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
          duration: const Duration(milliseconds: 600),
        );
      } else {
        print('Invalid bounds for city $cityName in $provinceName');
        await zoomToProvinceExtent(provinceName);
      }
    } catch (e) {
      print('Error zooming to city $cityName in $provinceName: $e');
      await zoomToProvinceExtent(provinceName);
    }
  }

  Future<void> initAsync() async {
    //uncomment if you want zoomout initially
    //initialCenter = await computePhilippinesCenter();
    await initializeYears(); // Fetch available years
    final data = await fetchRegionsData();
    if (!mounted) return;
    setState(() {
      regions = data;
      isMapLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void updateProvinces(String region) async {
    if (!mounted) return;
    setState(() {
      isProvincesLoading = true;
      selectedProvince = null;
      selectedCity = null;
      cities.clear();
    });

    final result = selectedYear != null
        ? await fetchProvinces(selectedYear!, region)
        : await fetchProvincesAcrossAllYears(region);

    if (!mounted) return;
    setState(() {
      provinces = result;
      isProvincesLoading = false;
    });
  }

  void updateCities(String province) async {
    if (!mounted) return;
    setState(() {
      isCitiesLoading = true;
      selectedCity = null;
    });

    final result = selectedYear != null
        ? await fetchCities(selectedYear!, province)
        : await fetchCitiesAcrossAllYears(province);

    if (!mounted) return;
    setState(() {
      cities = result;
      isCitiesLoading = false;
    });
  }

  void refreshData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final results = await fetchTrainingData(
      year: selectedYear,
      region: selectedRegion,
      province: selectedProvince,
      city: selectedCity,
      startMonth: selectedStartMonth,
      endMonth: selectedEndMonth,
    );

    if (!mounted) return;

    setState(() {
      trainingData = results;
      isLoading = false;
    });

    // Generate a new load ID to cancel previous one
    final currentLoadId = DateTime.now().millisecondsSinceEpoch.toString();
    _activeMarkerLoadId = currentLoadId;

    await loadTrainingMarkers(results, currentLoadId);
  }

  Future<void> moveToLocation(LatLng target, {double zoom = 5.8}) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (isMapLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialCenter ?? const LatLng(12.8797, 121.7740),
                      zoom: 5.8,
                    ),
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: false,
                    mapType: MapType.hybrid,
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController = controller;
                      await Future.delayed(const Duration(milliseconds: 200));
                      await zoomToPhilippinesExtent();
                    },
                    markers: _markers,
                    polygons: _polygons,
                  ),
                if (!isMapLoading) ...[
                  Positioned(
                    top: 15,
                    left: 16,
                    width: 450,
                    child: MouseRegion(
                      cursor: _searchFocusNode.hasFocus
                          ? SystemMouseCursors.text
                          : SystemMouseCursors.click,
                      child: SearchAndResults(
                        searchController: _searchController,
                        searchFocusNode: _searchFocusNode,
                        trainingData: trainingData,
                        shouldShowResults: hasSelectedAnyFilter,
                        isLoading: isLoading,
                        onTrainingSelected: (training) {
                          clearMarkers(); // You will define this inside MapPageState
                          zoomToTraining(
                              training); // You will define this inside MapPageState
                        },
                        onBackToList: () {
                          restoreAllMarkers(); // You will define this inside MapPageState
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 466,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: DropdownFilters(
                        years:
                            years.isNotEmpty ? years : ['No years available'],
                        months: months,
                        regions: regions,
                        provinces: provinces,
                        cities: cities,
                        selectedYear: selectedYear,
                        selectedRegion: selectedRegion,
                        selectedProvince: selectedProvince,
                        selectedCity: selectedCity,
                        selectedStartMonth: selectedStartMonth,
                        selectedEndMonth: selectedEndMonth,
                        onYearChanged: (value) {
                          print('Year changed: $value'); // Debug log
                          if (value == 'No years available') return;
                          setState(() {
                            selectedYear = selectedYear == value ? null : value;
                          });
                          if (selectedRegion != null) {
                            updateProvinces(selectedRegion!);
                          }
                          refreshData();
                        },
                        onStartMonthChanged: (value) {
                          print('Start Month changed: $value'); // Debug log
                          setState(() {
                            selectedStartMonth =
                                selectedStartMonth == value ? null : value;
                          });
                          refreshData();
                        },
                        onEndMonthChanged: (value) {
                          print('End Month changed: $value'); // Debug log
                          if (selectedStartMonth == null) return;
                          setState(() {
                            selectedEndMonth =
                                selectedEndMonth == value ? null : value;
                          });
                          refreshData();
                        },
                        onRegionChanged: (value) {
                          print('Region changed: $value'); // Debug log
                          setState(() {
                            selectedRegion =
                                selectedRegion == value ? null : value;
                            selectedProvince = null;
                            selectedCity = null;
                            cities.clear();
                            provinces.clear();
                          });
                          if (value != null) {
                            updateProvinces(value);
                            if (selectedProvince == null &&
                                selectedCity == null) {
                              zoomToRegionsExtent(value);
                            }
                          } else {
                            zoomToPhilippinesExtent();
                          }
                          refreshData();
                        },
                        onProvinceChanged: (value) {
                          print('Province changed: $value'); // Debug log
                          setState(() {
                            selectedProvince =
                                selectedProvince == value ? null : value;
                            selectedCity = null;
                            cities.clear();
                          });
                          if (value != null) {
                            updateCities(value);
                            zoomToProvinceExtent(value);
                          } else if (selectedRegion != null) {
                            zoomToRegionsExtent(selectedRegion!);
                          } else {
                            zoomToPhilippinesExtent();
                          }
                          refreshData();
                        },
                        onCityChanged: (value) {
                          print('City changed: $value'); // Debug log
                          setState(() {
                            selectedCity = selectedCity == value ? null : value;
                          });
                          if (value != null && selectedProvince != null) {
                            zoomToCityExtent(selectedProvince!, value);
                          } else if (selectedProvince != null) {
                            zoomToProvinceExtent(selectedProvince!);
                          } else if (selectedRegion != null) {
                            zoomToRegionsExtent(selectedRegion!);
                          } else {
                            zoomToPhilippinesExtent();
                          }
                          refreshData();
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
