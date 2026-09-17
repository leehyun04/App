# 아이지킴이 (kid_guard)

아이 이탈 방지 + 약속 장소 근접 찾기 앱. **GPS와 블루투스(BLE)를 함께 써서** 실외 원거리부터 실내 근거리까지 "상대와 얼마나 떨어져 있나"를 감지하고 알림을 줍니다.

- **이탈 방지 모드**: 아이가 설정 거리(기본 20m)보다 멀어지거나 신호가 끊기면 보호자에게 경고
- **약속 장소 찾기 모드**: 상대가 블루투스 범위(약 30m)에 들어오면 알림, 가까워질수록 "뜨겁다" 게이지

## 동작 원리

```
[내 기기]                                     [상대 기기]
 BLE 광고 (내 UUID) ───────────────────────▶ BLE 스캔 → RSSI
 BLE 스캔 ◀─────────────────────────── BLE 광고 (상대 UUID)
      │ RSSI                                     │
 GPS 위치 ──▶ Firestore pairs/{code} ◀── GPS 위치
      │            (원거리용, 선택)               │
      ▼                                          ▼
 ProximityEngine: BLE 살아있으면 RSSI 거리, 아니면 GPS 거리
      ▼
 AlertController: 상태 변화 → 로컬 푸시 알림
```

- **페어 코드 → BLE UUID**: 6자리 코드를 서비스 UUID에 직접 넣습니다 (`4b494447-5541-5244-0001-000000123456`). 상대는 "정확히 이 UUID"만 스캔하므로 다른 기기와 섞이지 않고, iOS 백그라운드 광고에서도 잡힙니다.
- **거리 우선순위**: BLE 신호가 살아있으면 RSSI 기반 거리(근거리·실내 정확), 끊기면 GPS 좌표 거리(원거리·실외). 둘 다 없으면 "끊김".
- **오탐 방지**: RSSI 지수이동평균 + 이탈 상태 6초 지속 후 알림.

## 프로젝트 구조

```
lib/
├── main.dart                     # 진입점. Firebase 있으면 GPS 동기화, 없으면 BLE 전용
├── app.dart                      # MaterialApp
├── core/
│   ├── constants.dart            # 거리·시간 임계값, RSSI 파라미터 (튜닝 포인트)
│   ├── geo_utils.dart            # Haversine 거리, 방위각, RSSI→거리 변환
│   └── pair_uuid.dart            # 페어 코드 → BLE 서비스 UUID
├── models/
│   ├── enums.dart                # PairRole, AppMode, ProximityLevel, DistanceSource
│   ├── pair_info.dart            # 저장되는 페어링 정보
│   ├── geo_fix.dart              # GPS 위치 한 점
│   └── proximity_state.dart      # 엔진 판정 결과
├── services/
│   ├── ble_service.dart          # BLE 광고(flutter_ble_peripheral) + 스캔(flutter_blue_plus)
│   ├── location_service.dart     # GPS 스트림 (geolocator)
│   ├── location_sync_service.dart# 상대 위치 교환 (Firestore / Noop)
│   ├── proximity_engine.dart     # BLE + GPS 융합 → 거리·단계 판정
│   ├── alert_controller.dart     # 모드별 알림 정책
│   ├── notification_service.dart # 로컬 푸시 (flutter_local_notifications)
│   ├── permission_service.dart   # 위치·블루투스·알림 권한
│   └── pairing_service.dart      # 코드 생성·저장 (shared_preferences)
├── providers/
│   └── app_state.dart            # 전체 오케스트레이션 (ChangeNotifier)
├── screens/
│   ├── home_screen.dart          # 헤더 + 모드별 화면 + 시작/중지 버튼
│   ├── pairing_screen.dart       # 코드 만들기 / 코드 입력
│   ├── guard_screen.dart         # 이탈 방지 화면
│   ├── find_screen.dart          # 약속 장소 찾기 화면
│   └── settings_screen.dart      # 모드·경고 거리·연결 해제
└── widgets/
    ├── proximity_gauge.dart      # 원형 근접 게이지
    ├── signal_chips.dart         # 신호 종류/RSSI/마지막 감지 칩
    └── level_style.dart          # 단계별 색·아이콘
android/app/src/main/AndroidManifest.xml   # BLE·위치·알림 권한
ios/Runner/Info.plist                      # 권한 설명 + 백그라운드 모드
firestore.rules                            # Firestore 보안 규칙 (MVP)
```

## 시작하기

### 1. Flutter 설치
https://docs.flutter.dev/get-started/install 에서 설치 후 `flutter doctor`로 확인.

### 2. 플랫폼 파일 생성
이 저장소에는 `lib/`, `pubspec.yaml`, 매니페스트/Info.plist만 있습니다. 나머지 Android/iOS 프로젝트 파일은 아래 명령으로 생성합니다. **기존 파일은 덮어쓰지 않습니다.**

```bash
flutter create --org com.example --project-name kid_guard --platforms android,ios .
```

### 3. 의존성 설치

```bash
flutter pub get
```

버전 충돌이 나면:

```bash
flutter pub upgrade --major-versions
```

### 4. Android 설정 확인
`android/app/build.gradle` (또는 `.kts`)에서 `minSdk`가 **21 이상**인지 확인 (BLE 필수). 기본값이 21이라 보통 그대로 됩니다.

### 5. 실행 (실기기 2대 필요)
에뮬레이터는 BLE 광고를 지원하지 않습니다. **실제 폰 2대**에 설치하세요.

```bash
flutter run
```

## 테스트 절차

1. 두 폰 모두 앱 설치, 블루투스·위치 켜기
2. 폰 A: "이탈 방지" 선택 → **새 코드 만들기** (보호자 역할)
3. 폰 B: "이탈 방지" 선택 → 코드 입력 → **코드로 참여** (아이 역할)
4. 양쪽 모두 **추적 시작** → 권한 모두 허용
5. 붙여놓으면 "바로 옆에 있어요", 떨어지면 거리가 올라가고, 경고 거리(설정에서 조절) 넘어 6초 지나면 경고 알림
6. 설정 → 모드를 "약속 장소 찾기"로 바꿔 뜨겁다/차갑다 게이지 확인

**RSSI 보정**: 폰마다 송신 세기가 달라 거리가 실제와 다를 수 있습니다. 두 폰을 정확히 1m 떨어뜨려 화면의 RSSI 값을 읽고 `constants.dart`의 `rssiAtOneMeter`를 그 값으로 바꾸세요. 실내에서 거리가 과대 추정되면 `pathLossExponent`를 3.0 정도로 올리세요.

## GPS 원거리 동기화 (Firebase, 선택)

Firebase 없이도 **블루투스 범위(약 30m) 안에서는 완전히 동작**합니다. 그 밖에서도 거리를 보려면:

1. https://console.firebase.google.com 에서 프로젝트 생성, Firestore 활성화
2. FlutterFire CLI 설치 및 설정
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. 생성된 `lib/firebase_options.dart`를 `main.dart`에서 import하고
   `Firebase.initializeApp()` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` 으로 변경
4. Firestore 규칙에 `firestore.rules` 내용 적용

앱은 Firebase 연결 성공 여부를 자동 감지해 설정 화면에 표시합니다.

Firebase를 아예 빼고 BLE 전용으로 쓰려면 `pubspec.yaml`에서 `firebase_core`, `cloud_firestore`를 지우고 `main.dart`의 `_initLocationSync`를 `NoopLocationSync()` 반환으로, `location_sync_service.dart`의 Firestore 구현을 삭제하면 됩니다.

## 현재 한계와 다음 단계

이 코드는 **앱이 화면에 떠 있을 때** 안정적으로 동작하는 MVP입니다. 실사용을 위해 다음이 필요합니다.

| 항목 | 현재 | 다음 단계 |
|------|------|-----------|
| 백그라운드 동작 (Android) | 화면 꺼지면 스캔이 느려지거나 중단됨 | `flutter_foreground_task`로 포그라운드 서비스 추가 (매니페스트 권한은 이미 선언됨) |
| 백그라운드 동작 (iOS) | Info.plist에 백그라운드 모드 선언됨. iOS↔iOS는 동작, Android 광고를 iOS 백그라운드에서 잡는 건 제한적 | 위치 업데이트로 앱을 깨우는 방식 병행 |
| 거리 정확도 | RSSI 추정 (±수 m, 벽·사람에 영향) | 기기별 보정 테이블, UWB(iPhone 11+/갤럭시 일부) 정밀 찾기 |
| 지도 표시 | 좌표 텍스트·방위만 | `google_maps_flutter` 또는 `flutter_map`으로 상대 마지막 위치 지도 표시 |
| 보안 | 6자리 코드가 유일한 인증 | Firebase Auth 연동, Firestore 규칙 강화, 위치 필드 암호화 |
| 다대일 | 1:1 페어만 | 보호자 여러 명 / 아이 여러 명 (코드당 여러 역할) |
| 아이 폰이 없는 경우 | 미지원 | BLE 태그(스마트태그류) 감지 모드 |

## 주요 패키지

| 패키지 | 역할 |
|--------|------|
| flutter_blue_plus | BLE 스캔 (central) |
| flutter_ble_peripheral | BLE 광고 (peripheral) |
| geolocator | GPS 위치 스트림 |
| flutter_local_notifications | 로컬 푸시 알림 |
| permission_handler | 런타임 권한 |
| cloud_firestore / firebase_core | 상대 GPS 위치 동기화 (선택) |
| provider | 상태 관리 |
| shared_preferences | 페어링 정보 저장 |
