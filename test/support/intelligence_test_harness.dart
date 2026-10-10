import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

/// Signature matching [BlocProvider]'s `create`.
typedef IntelligenceBlocFactory = IntelligenceBloc Function(
  BuildContext context,
);

/// A [BlocProvider.create] factory that builds an app-scoped
/// [IntelligenceBloc] backed by an in-memory progression store — the same
/// wiring [App] performs in production, minus persistence.
///
/// Screens read progression (level, XP, streaks, achievements, quests) from
/// this bloc, so any harness that pumps Dashboard, Activity, Contributions,
/// Profile, Progress or Settings needs it.
IntelligenceBlocFactory intelligenceProvider({
  ProgressionStore? store,
  DateTime Function()? clock,
}) {
  return (context) =>
      IntelligenceBloc(store ?? InMemoryProgressionStore(), clock: clock);
}
