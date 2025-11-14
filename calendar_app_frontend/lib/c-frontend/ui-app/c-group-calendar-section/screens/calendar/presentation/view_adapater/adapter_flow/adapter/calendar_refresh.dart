// calendar_refresh.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void safeBump(void Function() bump) {
  final phase = SchedulerBinding.instance.schedulerPhase;
  final inBuild = phase == SchedulerPhase.transientCallbacks ||
      phase == SchedulerPhase.persistentCallbacks ||
      phase == SchedulerPhase.postFrameCallbacks;
  if (inBuild) {
    WidgetsBinding.instance.addPostFrameCallback((_) => bump());
  } else {
    bump();
  }
}
