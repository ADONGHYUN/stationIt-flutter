import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보
import 'package:http/http.dart' as http; // API 통신
import 'dart:convert'; // JSON 파싱

void main() {
  runApp(const MyApp());
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
  List<String> _stations = [];

  @override
  void initState() {
    super.initState();
    _findNearestStationTest(); // 테스트용 더미 데이터 로드 (listView)
  }

  Future<void> _findNearestStationTest() async {
    setState(() {
      _stations = [
        '강남',
        '교대',
        '역삼',
        '선릉',
        '삼성',
        '봉은사',
        '종합운동장',
        '잠실새내',
        '잠실',
        '신천',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('현재 위치 지하철역'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // 가로 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(flex: 5),

              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stations.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        // color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _stations[index],
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 5),
            ],
          ),
        ),
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
