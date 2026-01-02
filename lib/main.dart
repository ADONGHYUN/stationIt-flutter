import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보
import 'package:http/http.dart' as http; // API 통신
import 'dart:convert'; // JSON 파싱
import 'dart:io'; // 플랫폼 확인용
import 'dart:async'; // Timer를 위해 추가

void main() {
  runApp(const MyApp());
}

class Station {
    final String name;
    final double latitude;
    final double longitude;
    final String lineName;
    final int stationOrder;

    Station({
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.lineName,
      required this.stationOrder,
  });

  // JSON 데이터를 객체로 변환
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      lineName: json['lineName'] ?? '',
      stationOrder: json['stationOrder'] ?? 0,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearest Station Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Station> _stations = [];
  bool _isLoading = false;
  bool _showSplash = true;
  final double _cardWidth = 200.0; // 역 카드의 가로 너비 설정
  // 에뮬레이터 환경에 따른 주소 설정 (Android: 10.0.2.2 / iOS: localhost)
  final String _baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8080'
      : 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _initApp();
  }


  Future<void> _initApp() async {
    // 2초간 로고 보여줌
    await Future.delayed(const Duration(seconds: 2));

    // 2. 로고 화면 해제
    setState(() {
      _showSplash = false;
    });

    // 3. 그 다음 위치 및 데이터 가져오기 시작
    _fetchLocationAndStations();
  }

  Future<void> _fetchLocationAndStations() async {
    setState(() => _isLoading = true);

    try {
      // 1. 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return;
      }

      // 2. 현재 위치 가져오기
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      await _getNearestStationsFromServer(position.latitude, position.longitude);
    } catch (e) {
      _showErrorSnackBar("오류 발생: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 백엔드 API와 통신
  Future<void> _getNearestStationsFromServer(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/api/nearest-station?lat=$lat&lon=$lon');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // UTF-8 디코딩 후 JSON 파싱
        final Map<String, dynamic> decodedData = json.decode(
          utf8.decode(response.bodyBytes),
        );

        // Map<String, dynamic>에서 Station 객체들만 추출하여 리스트 생성
        List<Station> tempStations = [];
        decodedData.forEach((key, value) {
          tempStations.add(Station.fromJson(value));
        });

        setState(() {
          _stations = tempStations;
        });
      } else {
        _showErrorSnackBar("서버 오류: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("서버 연결 실패. 백엔드가 켜져있는지 확인하세요.");
      print(e);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 데이터 없을 때와 앱 오픈시 이미지로딩(로컬 assets 사용)
  Widget _buildLogoState(BuildContext context, {String message = "주변 지하철역을 찾는 중..."}) {
    // 화면 너비의 65% 크기로 설정
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.65;

    return SizedBox(
      width: double.infinity, // 가로로 꽉 차게
      child: Column(
        children: [
          const Spacer(flex: 3), // 상단 여백
          Image.asset(
            'assets/app_logo.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain, // 비율 유지하며 크기 맞춤
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.subway, size: logoSize / 2, color: Colors.green.withOpacity(0.5)),
          ),
          const SizedBox(height: 40),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isLoading) ...[
            const SizedBox(height: 30),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.green),
            ),
          ],
          const Spacer(flex: 4), // 하단 여백
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double sidePadding = (screenWidth - _cardWidth) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showSplash ? null : AppBar( // 로고 화면일 때는 앱바도 숨김
        title: const Text('현재 지하철역'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLocationAndStations)
        ],
      ),
      body: _showSplash
          ? _buildLogoState(context, message: "역잇")
          : _isLoading && _stations.isEmpty
          ? _buildLogoState(context, message: "내 위치를 확인하고 있습니다...")
          : _stations.isEmpty
          ? _buildLogoState(context, message: "주변에 역이 없거나\n위치를 찾을 수 없습니다.")
          : Column(
        children: [
          const Spacer(flex: 2),
          const Text("현재역", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              physics: const BouncingScrollPhysics(),
              itemCount: _stations.length,
              itemBuilder: (context, index) => _buildStationCard(_stations[index]),
            ),
          ),
          const SizedBox(height: 20),
          const Text("← 밀어서 다른 역 확인 →", style: TextStyle(fontSize: 14, color: Colors.black26)),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildStationCard(Station station) {
    return Container(
      width: _cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
            child: Text(station.lineName, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(height: 10),
          Text(station.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// class _HomeScreenState extends State<HomeScreen> {
//   String _nearestStationName =
//       "위치 확인 중..."; // _stationName -> _nearestStationName
//   String? _prevStationName; // 이전 역 이름 상태 추가
//   String? _nextStationName; // 다음 역 이름 상태 추가
//   bool _isLoading = true;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _findNearestStationTest(); // 테스트용 더미 데이터 로드 (listView)
//     // _findNearestStation(); // 앱이 시작되면 즉시 위치 찾기 시작
//   }

//   Future<void> _findNearestStationTest() async {
//     setState(() {
//       _stations = ['강남', '교대', '역삼', '선릉', '삼성'];
//     });
//   }

//   Future<void> _findNearestStation() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _prevStationName = null; // 새로고침 시 초기화
//       _nextStationName = null; // 새로고침 시 초기화
//     });

//     try {
//       // 1. 위치 권한 확인 및 요청
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           throw Exception('위치 권한이 거부되었습니다.');
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요.');
//       }

//       // 2. 현재 위치(위도, 경도) 가져오기
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium,
//       ); // 정확도 설정

//       // --- 3. 스프링 부트 백엔드 API 호출 ---
//       // 중요:
//       // - 안드로이드 에뮬레이터에서 로컬호스트(127.0.0.1)를 호출하려면 10.0.2.2를 사용해야 합니다.
//       // - iOS 시뮬레이터나 실제 기기에서는 localhost 또는 PC의 IP 주소를 사용해야 합니다.
//       //
//       // !!! (수정) 플러터 '웹' 환경에서는 'localhost'를 직접 사용합니다. !!!
//       const String apiUrl = "http://localhost:8080/api/nearest-station";
//       final Uri uri = Uri.parse(
//         '$apiUrl?lat=${position.latitude}&lon=${position.longitude}',
//       );

//       final response = await http.get(uri);

//       if (response.statusCode == 200) {
//         // 4. API 응답(JSON) 파싱
//         // Spring Boot가 UTF-8로 응답하므로, jsonDecode로 한글을 처리합니다.
//         final data = jsonDecode(utf8.decode(response.bodyBytes));

//         // 응답이 Map 형태({ "nearest": {...}, "previous": {...} })로 변경됨
//         final String nearestName = data['nearest']?['name'] ?? '정보 없음';
//         final String? prevName = data['previous']?['name'];
//         final String? nextName = data['next']?['name'];

//         setState(() {
//           _nearestStationName = nearestName;
//           _prevStationName = prevName;
//           _nextStationName = nextName;
//         });
//       } else {
//         throw Exception(
//           '서버에서 응답을 받지 못했습니다. (Status code: ${response.statusCode})',
//         );
//       }
//     } catch (e) {
//       // 5. 에러 처리
//       setState(() {
//         _errorMessage = e.toString();
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('현재 위치 지하철역'),
//         backgroundColor: Colors.green,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               // 로고 또는 아이콘 (지하철 모양)
//               const Icon(Icons.subway, size: 100, color: Colors.green),
//               const SizedBox(height: 30),

//               const Text(
//                 '2호선',
//                 style: TextStyle(fontSize: 18),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),

//               // 로딩 중, 에러 발생, 또는 결과 표시에 따라 다른 위젯을 보여줌
//               _buildResultWidget(),
//               const SizedBox(height: 40),

//               // 새로고침 버튼
//               ElevatedButton.icon(
//                 onPressed: _isLoading
//                     ? null
//                     : _findNearestStation, // 로딩 중에는 비활성화
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('현재 위치 새로고침'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green[700],
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 12,
//                   ),
//                   textStyle: const TextStyle(fontSize: 16),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // 상태에 따라 다른 위젯을 반환하는 헬퍼 함수
//   Widget _buildResultWidget() {
//     if (_isLoading) {
//       // 로딩 중
//       return const CircularProgressIndicator();
//     } else if (_errorMessage != null) {
//       // 에러 발생
//       return Text(
//         '오류: $_errorMessage',
//         style: const TextStyle(color: Colors.red, fontSize: 16),
//         textAlign: TextAlign.center,
//       );
//     } else {
//       // 성공
//       // 이전/다음 역을 함께 표시하도록 UI 수정
//       return Column(
//         children: [
//           const Text(
//             '현재 역',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           Text(
//             _nearestStationName,
//             style: const TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 30),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // 이전 역
//               Expanded(
//                 child: Column(
//                   children: [
//                     const Text(
//                       '이전 역',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _prevStationName ?? ' (없음)', // null이면 "없음" 표시
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               // 다음 역
//               Expanded(
//                 child: Column(
//                   children: [
//                     const Text(
//                       '다음 역',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _nextStationName ?? ' (없음)', // null이면 "없음" 표시
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       );
//     }
//   }
// }
