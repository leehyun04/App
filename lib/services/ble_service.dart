import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart' as peripheral;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 블루투스 근접 감지.
///
/// 두 기기가 동시에
///  1) 내 UUID를 광고(advertise)하고
///  2) 상대 UUID를 스캔(scan)한다.
/// 상대 광고가 잡힐 때마다 RSSI(신호 세기)를 [rssiStream]으로 내보낸다.
class BleService {
  final peripheral.FlutterBlePeripheral _peripheral =
      peripheral.FlutterBlePeripheral();

  StreamSubscription<List<ScanResult>>? _scanSub;
  final StreamController<int> _rssiController =
      StreamController<int>.broadcast();
  DateTime? _lastEmittedAt;
  bool _advertising = false;

  /// 상대 기기 RSSI(dBm). 신호가 잡힐 때만 흘러나온다.
  Stream<int> get rssiStream => _rssiController.stream;

  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  /// 블루투스 지원 여부 + 켜져 있는지 확인
  Future<bool> isReady() async {
    if (!await FlutterBluePlus.isSupported) return false;
    try {
      final state = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 3));
      return state == BluetoothAdapterState.on;
    } on TimeoutException {
      // 상태를 못 읽으면 일단 시도해 본다
      return true;
    }
  }

  Future<void> start({
    required String advertiseUuid,
    required String scanUuid,
  }) async {
    await stop();
    await _startAdvertising(advertiseUuid);
    await _startScanning(scanUuid);
  }

  Future<void> _startAdvertising(String uuid) async {
    final data = peripheral.AdvertiseData(
      serviceUuid: uuid,
      includeDeviceName: false,
    );
    final settings = peripheral.AdvertiseSettings(
      advertiseMode: peripheral.AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: peripheral.AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: false,
      timeout: 0, // 0 = 무제한
    );
    await _peripheral.start(advertiseData: data, advertiseSettings: settings);
    _advertising = true;
    debugPrint('[BLE] advertising $uuid');
  }

  Future<void> _startScanning(String uuid) async {
    final guid = Guid(uuid);
    _lastEmittedAt = null;

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        // withServices 필터가 걸려 있어 결과는 상대 기기만 오지만,
        // 같은 결과가 재전달되는 경우를 걸러내기 위해 타임스탬프를 비교한다.
        final last = _lastEmittedAt;
        if (last != null && !r.timeStamp.isAfter(last)) continue;
        _lastEmittedAt = r.timeStamp;
        _rssiController.add(r.rssi);
      }
    }, onError: (Object e) => debugPrint('[BLE] scan error: $e'));

    await FlutterBluePlus.startScan(
      withServices: [guid],
      continuousUpdates: true,
      removeIfGone: const Duration(seconds: 5),
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );
    debugPrint('[BLE] scanning for $uuid');
  }

  Future<void> stop() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      debugPrint('[BLE] stopScan error: $e');
    }
    if (_advertising) {
      try {
        await _peripheral.stop();
      } catch (e) {
        debugPrint('[BLE] stop advertising error: $e');
      }
      _advertising = false;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _rssiController.close();
  }
}
