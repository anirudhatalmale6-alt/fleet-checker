import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/van_model.dart';
import '../models/inspection_model.dart';
import 'data_service.dart';

class MockDataService extends DataService {
  final _uuid = const Uuid();
  final List<Van> _vans = [];
  final List<Inspection> _inspections = [];

  final _vansController = StreamController<List<Van>>.broadcast();
  final _inspectionsController =
      StreamController<List<Inspection>>.broadcast();

  MockDataService() {
    _seedData();
  }

  void _seedData() {
    _vans.addAll([
      Van(
        id: 'demo-van-1',
        registration: 'AB12 CDE',
        make: 'Ford',
        model: 'Transit',
        mileage: 45230,
        ownerId: 'demo-owner-1',
        vehicleType: 'Van',
        assignedDriverId: 'demo-driver-1',
        assignedDriverName: 'James Wilson',
      ),
      Van(
        id: 'demo-van-2',
        registration: 'XY34 FGH',
        make: 'Mercedes',
        model: 'Sprinter',
        mileage: 32100,
        ownerId: 'demo-owner-1',
        vehicleType: 'Van',
      ),
      Van(
        id: 'demo-van-3',
        registration: 'LM56 JKL',
        make: 'Volvo',
        model: 'FH16',
        mileage: 89400,
        ownerId: 'demo-owner-1',
        vehicleType: 'Truck',
      ),
    ]);

    // Seed a recent inspection
    _inspections.add(Inspection(
      id: 'demo-insp-1',
      vanId: 'demo-van-1',
      vanRegistration: 'AB12 CDE',
      driverId: 'demo-driver-1',
      driverName: 'James Wilson',
      ownerId: 'demo-owner-1',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      mileage: 45230,
      checklist: [
        ChecklistItem(name: 'Lights', status: CheckStatus.pass),
        ChecklistItem(name: 'Tyres', status: CheckStatus.pass),
        ChecklistItem(name: 'Mirrors', status: CheckStatus.pass),
        ChecklistItem(name: 'Body Condition', status: CheckStatus.pass),
        ChecklistItem(name: 'Windscreen', status: CheckStatus.pass),
        ChecklistItem(name: 'Brakes', status: CheckStatus.pass),
        ChecklistItem(name: 'Fluids', status: CheckStatus.fail, notes: 'Washer fluid low'),
        ChecklistItem(name: 'Indicators', status: CheckStatus.pass),
        ChecklistItem(name: 'Horn', status: CheckStatus.pass),
        ChecklistItem(name: 'Seatbelt', status: CheckStatus.pass),
      ],
      status: InspectionStatus.failed,
      generalNotes: 'Washer fluid needs topping up',
    ));
  }

  // Helper to create stream with initial value
  Stream<List<T>> _streamWithInitial<T>(
      List<T> initial, Stream<List<T>> updates) {
    return Stream.value(initial).asyncExpand((first) async* {
      yield first;
      yield* updates;
    });
  }

  @override
  Stream<List<Van>> watchVansForOwner(String ownerId) {
    final getOwnerVans = () => _vans
        .where((v) => v.ownerId == ownerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _streamWithInitial(
      getOwnerVans(),
      _vansController.stream.map((_) => getOwnerVans()),
    );
  }

  @override
  Stream<List<Van>> watchVansForDriver(String driverId) {
    final getDriverVans = () =>
        _vans.where((v) => v.assignedDriverId == driverId).toList();

    return _streamWithInitial(
      getDriverVans(),
      _vansController.stream.map((_) => getDriverVans()),
    );
  }

  @override
  Future<Van?> getVanById(String id) async {
    try {
      return _vans.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addVan({
    required String registration,
    required String make,
    required String model,
    required int mileage,
    required String ownerId,
    String vehicleType = 'Van',
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _vans.add(Van(
      id: _uuid.v4(),
      registration: registration.toUpperCase(),
      make: make,
      model: model,
      mileage: mileage,
      ownerId: ownerId,
      vehicleType: vehicleType,
    ));
    _vansController.add(_vans);
  }

  @override
  Future<void> updateVan(String vanId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _vans.indexWhere((v) => v.id == vanId);
    if (idx >= 0) {
      final van = _vans[idx];
      if (data.containsKey('registration')) {
        van.registration = data['registration'];
      }
      if (data.containsKey('make')) van.make = data['make'];
      if (data.containsKey('model')) van.model = data['model'];
      if (data.containsKey('mileage')) van.mileage = data['mileage'];
      if (data.containsKey('vehicleType')) {
        van.vehicleType = data['vehicleType'];
      }
      if (data.containsKey('assignedDriverId')) {
        van.assignedDriverId = data['assignedDriverId'];
      }
      if (data.containsKey('assignedDriverName')) {
        van.assignedDriverName = data['assignedDriverName'];
      }
      _vansController.add(_vans);
    }
  }

  @override
  Future<void> deleteVan(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _vans.removeWhere((v) => v.id == id);
    _vansController.add(_vans);
  }

  @override
  Future<void> assignDriver(
      String vanId, String? driverId, String? driverName) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _vans.indexWhere((v) => v.id == vanId);
    if (idx >= 0) {
      _vans[idx].assignedDriverId = driverId;
      _vans[idx].assignedDriverName = driverName;
      _vansController.add(_vans);
    }
  }

  @override
  Stream<List<Inspection>> watchInspectionsForOwner(String ownerId) {
    final getInspections = () => _inspections
        .where((i) => i.ownerId == ownerId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return _streamWithInitial(
      getInspections(),
      _inspectionsController.stream.map((_) => getInspections()),
    );
  }

  @override
  Stream<List<Inspection>> watchInspectionsForDriver(String driverId) {
    final getInspections = () => _inspections
        .where((i) => i.driverId == driverId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return _streamWithInitial(
      getInspections(),
      _inspectionsController.stream.map((_) => getInspections()),
    );
  }

  @override
  Future<void> addInspection({
    required String vanId,
    required String vanRegistration,
    required String driverId,
    required String driverName,
    required String ownerId,
    required int mileage,
    required List<ChecklistItem> checklist,
    required InspectionStatus status,
    String? generalNotes,
    List<Uint8List> photoBytes = const [],
    Map<String, List<Uint8List>> itemPhotoBytes = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    _inspections.add(Inspection(
      id: _uuid.v4(),
      vanId: vanId,
      vanRegistration: vanRegistration,
      driverId: driverId,
      driverName: driverName,
      ownerId: ownerId,
      date: DateTime.now(),
      mileage: mileage,
      checklist: checklist,
      generalNotes: generalNotes,
      status: status,
    ));

    // Update van mileage
    final vanIdx = _vans.indexWhere((v) => v.id == vanId);
    if (vanIdx >= 0) {
      _vans[vanIdx].mileage = mileage;
      _vansController.add(_vans);
    }

    _inspectionsController.add(_inspections);
  }

  @override
  void dispose() {
    _vansController.close();
    _inspectionsController.close();
    super.dispose();
  }
}
