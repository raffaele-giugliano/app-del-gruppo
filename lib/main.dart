import 'package:flutter/material.dart';
import 'models/app_config.dart';
import 'screens/group_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfig(groupName: '');

    return MaterialApp(
      title: 'App del Gruppo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: GroupSelectionScreen(
        backendBaseUrl: appConfig.backendBaseUrl,
      ),
    );
  }
}