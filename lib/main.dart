import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'fx/finny_fx.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Прогрев звуков — без блокировки старта.
  FinnyFx.warmUp();
  runApp(const ProviderScope(child: FinnyApp()));
}
