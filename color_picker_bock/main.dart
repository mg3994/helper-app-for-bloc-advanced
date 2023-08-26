import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => ThemeModeBloc(
          themeModeRepository:
              LocalThemeModeRepository(SharedPrefLocalStorage()),
        )..add(FetchThemeModeEvent()),
        child: ThemeSettingsScreen(),
      ),
    );
  }
}

abstract class LocalStorage {
  Future<bool> setBool({required String key, required bool value});
  Future<bool> getBool({required String key});
  Future<String?> getString({required String key});
  Future<bool> setString({required String key, required String value});
}

class SharedPrefLocalStorage implements LocalStorage {
  @override
  Future<bool> getBool({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  @override
  Future<bool> setBool({required String key, required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  @override
  Future<String?> getString({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<bool> setString({required String key, required String value}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }
}

class LocalStorageKey {
  static const isDarkMode = "isDarkMode";
  static const colorScheme = "colorScheme";
}

abstract class ThemeModeRepository {
  Future<ThemeData> getThemeData();
  Future<bool> updateThemeData({required ThemeData themeData});
}

class LocalThemeModeRepository implements ThemeModeRepository {
  final LocalStorage localStorage;
  LocalThemeModeRepository(this.localStorage);

  @override
  Future<ThemeData> getThemeData() async {
    final colorHex =
        await localStorage.getString(key: LocalStorageKey.colorScheme);
    final seedColor = Color(int.parse(colorHex ?? "0xFF345487"));
    final colorScheme = ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(seedColor.value, {}),
        brightness: Brightness.light);
    return ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
  }

  @override
  Future<bool> updateThemeData({required ThemeData themeData}) async {
    final colorHex = themeData.primaryColor.value.toRadixString(16);
    return localStorage.setString(
        key: LocalStorageKey.colorScheme, value: colorHex);
  }
}

class ThemeModeEvent {}

class FetchThemeModeEvent extends ThemeModeEvent {}

class UpdateThemeModeEvent extends ThemeModeEvent {
  final ThemeData themeData;
  UpdateThemeModeEvent({required this.themeData});
}

class ThemeModeState {
  final ThemeData themeData;
  ThemeModeState(this.themeData);
}

class ThemeModeBloc extends Bloc<ThemeModeEvent, ThemeModeState> {
  final ThemeModeRepository themeModeRepository;

  ThemeModeBloc({required this.themeModeRepository})
      : super(ThemeModeState(ThemeData.from(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF345487),
          ),
        )));

  // @override
  Stream<ThemeModeState> mapEventToState(ThemeModeEvent event) async* {
    if (event is FetchThemeModeEvent) {
      ThemeData themeData = await themeModeRepository.getThemeData();
      yield ThemeModeState(themeData);
    } else if (event is UpdateThemeModeEvent) {
      bool success =
          await themeModeRepository.updateThemeData(themeData: event.themeData);
      if (success) {
        yield ThemeModeState(event.themeData);
      }
    }
  }
}

class ThemeSettingsScreen extends StatefulWidget {
  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  Color _selectedColor = const Color(0xFF345487);

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ThemeModeBloc>().add(UpdateThemeModeEvent(
                      themeData: ThemeData.from(
                        useMaterial3: true,
                        colorScheme: ColorScheme.fromSwatch(
                          primarySwatch:
                              MaterialColor(_selectedColor.value, {}),
                          brightness: Brightness.light,
                        ),
                      ),
                    ));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theme Settings')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showColorPicker(context),
          child: Text(
            'Change Theme Color',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}
