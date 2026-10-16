import 'package:flutter/material.dart';
import 'package:flutter_ci_quality_template/app/bindings/initial_binding.dart';
import 'package:flutter_ci_quality_template/app/routes/app_pages.dart';
import 'package:get/get.dart';

/// Application root. Owns theming, routing and the global dependency graph.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter CI Quality Template',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
