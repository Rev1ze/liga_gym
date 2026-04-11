enum GoalSettingsSection {
  steps,
  calories,
  progress,
}

class GoalSettingsRouteArguments {
  const GoalSettingsRouteArguments({required this.section});

  final GoalSettingsSection section;
}
