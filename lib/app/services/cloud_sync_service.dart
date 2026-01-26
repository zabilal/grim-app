import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/goals/controllers/goals_controller.dart';
import '../modules/execution/controllers/execution_controller.dart';
import '../modules/settings/controllers/settings_controller.dart';

class CloudSyncService extends GetxService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final storage = GetStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debounce timers to prevent excessive writes
  final Map<String, Timer> _debounceTimers = {};
  static const Duration _debounceDelay = Duration(seconds: 2);

  // Track last sync timestamps to avoid conflicts
  final Map<String, Timestamp> _lastSyncTimestamps = {};

  @override
  void onInit() {
    super.onInit();
    _setupRealtimeListeners();
  }

  bool get isLoggedIn => _auth.currentUser != null;
  bool get isCloudSyncEnabled => storage.read('cloudSync') ?? false;

  /// Setup real-time listeners for Firestore data
  void _setupRealtimeListeners() {
    if (!isLoggedIn || !isCloudSyncEnabled) return;

    final user = _auth.currentUser!;
    final userDoc = _firestore.collection('users').doc(user.uid);

    // Listen for goals changes
    userDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _syncFromCloudIfNeeded('goals', data['goals'] ?? []);
        _syncFromCloudIfNeeded('tasks', data['tasks'] ?? []);
        _syncFromCloudIfNeeded('topGoals', data['topGoals'] ?? {});
        _syncFromCloudIfNeeded('settings', data['settings'] ?? {});
      }
    });
  }

  /// Sync data to cloud with debouncing
  Future<void> syncDataToCloud(String dataType, dynamic data) async {
    if (!isLoggedIn || !isCloudSyncEnabled) return;

    try {
      final user = _auth.currentUser!;
      final userDoc = _firestore.collection('users').doc(user.uid);

      // Cancel existing debounce timer for this data type
      _debounceTimers[dataType]?.cancel();

      // Set new debounce timer
      _debounceTimers[dataType] = Timer(_debounceDelay, () async {
        await _performCloudSync(dataType, data, userDoc);
        _debounceTimers.remove(dataType);
      });
    } catch (e) {
      print('Error queuing cloud sync for $dataType: $e');
    }
  }

  /// Perform the actual cloud sync
  Future<void> _performCloudSync(
    String dataType,
    dynamic data,
    DocumentReference userDoc,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'lastSync': FieldValue.serverTimestamp(),
        'email': _auth.currentUser!.email,
      };

      // Add specific data type
      switch (dataType) {
        case 'goals':
          updateData['goals'] = data;
          break;
        case 'tasks':
          updateData['tasks'] = data;
          break;
        case 'topGoals':
          updateData['topGoals'] = data;
          break;
        case 'settings':
          updateData['settings'] = data;
          break;
      }

      await userDoc.set(updateData, SetOptions(merge: true));
      _lastSyncTimestamps[dataType] = Timestamp.now();

      print('Successfully synced $dataType to cloud');
    } catch (e) {
      print('Error syncing $dataType to cloud: $e');
    }
  }

  /// Sync from cloud if data is newer
  void _syncFromCloudIfNeeded(String dataType, dynamic cloudData) {
    try {
      // Get current local data
      final dashboardController = Get.find<DashboardController>();
      final currentQuarter = dashboardController.currentQuarter.value;
      final currentYear = dashboardController.currentYear.value;

      String localKey;
      switch (dataType) {
        case 'goals':
          localKey = 'goals_${currentQuarter}_${currentYear}';
          break;
        case 'tasks':
          localKey = 'execution_tasks_${currentQuarter}_${currentYear}';
          break;
        case 'topGoals':
          localKey = 'top_goals_per_day_${currentQuarter}_${currentYear}';
          break;
        case 'settings':
          localKey = 'settings';
          break;
        default:
          return;
      }

      final localData = storage.read(localKey);

      // Simple comparison - in production, you'd want more sophisticated conflict resolution
      if (cloudData != null && cloudData != localData) {
        storage.write(localKey, cloudData);
        print('Synced $dataType from cloud');

        // Refresh relevant controllers
        _refreshControllers(dataType);
      }
    } catch (e) {
      print('Error syncing $dataType from cloud: $e');
    }
  }

  /// Refresh controllers when data is synced from cloud
  void _refreshControllers(String dataType) {
    try {
      switch (dataType) {
        case 'goals':
          if (Get.isRegistered<GoalsController>()) {
            Get.find<GoalsController>().loadGoals();
          }
          break;
        case 'tasks':
        case 'topGoals':
          if (Get.isRegistered<ExecutionController>()) {
            final controller = Get.find<ExecutionController>();
            controller.loadTasks();
            controller.loadTopGoal();
          }
          break;
        case 'settings':
          if (Get.isRegistered<SettingsController>()) {
            Get.find<SettingsController>().loadSettings();
          }
          break;
      }
    } catch (e) {
      print('Error refreshing controllers for $dataType: $e');
    }
  }

  /// Force immediate sync (for manual sync button)
  Future<void> forceSyncToCloud() async {
    if (!isLoggedIn || !isCloudSyncEnabled) return;

    try {
      final user = _auth.currentUser!;
      final dashboardController = Get.find<DashboardController>();
      final currentQuarter = dashboardController.currentQuarter.value;
      final currentYear = dashboardController.currentYear.value;

      // Get all current data
      final goalsData =
          storage.read('goals_${currentQuarter}_${currentYear}') ?? [];
      final tasksData =
          storage.read('execution_tasks_${currentQuarter}_${currentYear}') ??
          [];
      final topGoalsData =
          storage.read('top_goals_per_day_${currentQuarter}_${currentYear}') ??
          {};
      final settingsData = {
        'notifications': storage.read('notifications') ?? true,
        'strictMode': storage.read('strictMode') ?? true,
        'blockSocial': storage.read('blockSocial') ?? true,
        'deepWorkHours': storage.read('deepWorkHours') ?? 4,
      };

      // Sync all data immediately
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'lastSync': FieldValue.serverTimestamp(),
        'goals': goalsData,
        'tasks': tasksData,
        'topGoals': topGoalsData,
        'settings': settingsData,
      }, SetOptions(merge: true));

      print('Force sync completed successfully');
    } catch (e) {
      print('Error during force sync: $e');
    }
  }

  /// Call this method when cloud sync is enabled/disabled
  void updateCloudSyncStatus() {
    if (isLoggedIn && isCloudSyncEnabled) {
      _setupRealtimeListeners();
    } else {
      // Cancel all debounce timers
      for (final timer in _debounceTimers.values) {
        timer.cancel();
      }
      _debounceTimers.clear();
    }
  }

  @override
  void onClose() {
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    super.onClose();
  }
}

// Extension to make it easier to call from controllers
extension CloudSync on GetxController {
  void syncToCloud(String dataType, dynamic data) {
    final cloudSync = Get.find<CloudSyncService>();
    cloudSync.syncDataToCloud(dataType, data);
  }
}
