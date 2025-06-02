import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng _center = LatLng(36.7365, 127.0745);
  LatLng _userPosition = LatLng(36.7365, 127.0745);
  KakaoMapController? _mapController;
  List<Map<String, dynamic>> _gymList = [];
  List<Marker> _gymMarkers = [];

  // 권한 확인 메서드
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 허용해주세요.');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 위치 업데이트 메서드
  Future<void> _updateLocation() async {
    bool hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _userPosition = userLatLng);
      _mapController?.panTo(userLatLng);
      await _getNearbyGyms(userLatLng.latitude, userLatLng.longitude);
    } catch (e) {
      _showSnackBar('위치 정보를 가져오는 데 실패했습니다: ${e.toString()}');
    }
  }

  Future<void> _getNearbyGyms(double lat, double lng) async {
    const apiKey = '730dd63d9169f3bdad8fd3167e85289d';
    final response = await http.get(
      Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=배드민턴장&y=$lat&x=$lng&radius=5000',
      ),
      headers: {'Authorization': 'KakaoAK $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List gyms = data['documents'];
      setState(() {
        _gymList =
            gyms
                .map<Map<String, dynamic>>(
                  (gym) => {
                    'id': gym['id'],
                    'name': gym['place_name'],
                    'lat': double.parse(gym['y']),
                    'lng': double.parse(gym['x']),
                    'address':
                        gym['road_address_name'] ?? gym['address_name'] ?? '',
                    'phone': gym['phone'] ?? '정보 없음',
                  },
                )
                .toList();
        _updateMarkers();
      });
    }
  }

  void _updateMarkers() {
    _gymMarkers =
        _gymList.map<Marker>((gym) {
          return Marker(
            markerId: gym['id'],
            latLng: LatLng(gym['lat'], gym['lng']),
            markerImageSrc:
                'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
            width: 40,
            height: 42,
          );
        }).toList();
  }

  void _showGymInfo(String markerId) {
    final gym = _gymList.firstWhere(
      (g) => g['id'] == markerId,
      orElse: () => {},
    );
    if (gym.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(gym['name']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('주소: ${gym['address']}'),
                Text('전화번호: ${gym['phone']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('닫기'),
              ),
            ],
          ),
    );
  }

  void _showGymList() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (_gymList.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Text('근처 배드민턴장이 없습니다.'),
          );
        }
        return ListView.builder(
          itemCount: _gymList.length,
          itemBuilder: (context, index) {
            final gym = _gymList[index];
            return ListTile(
              leading: Icon(Icons.sports_tennis, color: Colors.red),
              title: Text(gym['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('주소: ${gym['address']}'),
                  Text('전화번호: ${gym['phone']}'),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                final gymLatLng = LatLng(gym['lat'], gym['lng']);
                _mapController?.panTo(gymLatLng);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('카카오 맵')),
      body: Stack(
        children: [
          KakaoMap(
            center: _center,
            onMapCreated: (controller) => _mapController = controller,
            markers: [
              Marker(markerId: 'user', latLng: _userPosition),
              ..._gymMarkers,
            ],
            onMarkerTap: (markerId, latLng, zoomLevel) {
              if (markerId == 'user') return;
              _showGymInfo(markerId);
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: Icon(Icons.list),
              label: Text('배드민턴장 리스트'),
              onPressed: _showGymList,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateLocation,
        child: Icon(Icons.my_location),
        tooltip: '내 위치로 이동',
      ),
    );
  }
}
