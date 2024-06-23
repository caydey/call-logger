import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_interface.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MaterialApp(
    title: "Logger",
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.system,
    theme: ThemeClass.lightTheme,
    darkTheme: ThemeClass.darkTheme,
    home: Application(
      preferences: prefs,
    ),
  ));
}
