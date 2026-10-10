import 'package:flutter/material.dart';

import 'services/firebase/firebase_service.dart';
import 'services/progression/progression_store.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely handles missing configuration/secrets in dev)
  await FirebaseService.instance.initialize();

  // Progression history (non-sensitive) is restored before the first frame so
  // achievements and completed quests are never briefly missing.
  final progressionStore = await loadProgressionStore();

  runApp(App(progressionStore: progressionStore));
}
