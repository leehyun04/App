import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/geo_fix.dart';

/// 두 기기 사이 GPS 위치를 주고받는 채널.
///
/// 블루투스 범위(수십 m)를 벗어난 원거리에서 거리를 계산하려면 서버가 필요하다.
/// 서버 구현은 교체 가능하며, 기본은 Firestore.
abstract class LocationSyncService {
  /// 서버가 설정돼 있어 실제로 동기화가 되는지
  bool get isAvailable;

  /// 내 위치를 올린다
  Future<void> publish(String code, PairRole role, GeoFix fix);

  /// 상대 위치를 구독한다. 아직 없으면 null
  Stream<GeoFix?> watchPartner(String code, PairRole partnerRole);
}

/// Firebase 미설정 시 사용. 블루투스만으로 동작한다.
class NoopLocationSync implements LocationSyncService {
  @override
  bool get isAvailable => false;

  @override
  Future<void> publish(String code, PairRole role, GeoFix fix) async {}

  @override
  Stream<GeoFix?> watchPartner(String code, PairRole partnerRole) =>
      Stream<GeoFix?>.value(null);
}

/// Firestore 구현.
///
/// 문서 구조: pairs/{code} = { host: {lat,lng,acc,ts}, guest: {...}, updatedAt }
class FirestoreLocationSync implements LocationSyncService {
  FirestoreLocationSync({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _db.collection('pairs').doc(code);

  @override
  bool get isAvailable => true;

  @override
  Future<void> publish(String code, PairRole role, GeoFix fix) {
    return _doc(code).set(
      {
        role.name: fix.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Stream<GeoFix?> watchPartner(String code, PairRole partnerRole) {
    return _doc(code).snapshots().map((snap) {
      final data = snap.data();
      final raw = data?[partnerRole.name];
      if (raw is! Map) return null;
      return GeoFix.fromMap(Map<String, dynamic>.from(raw));
    });
  }
}
