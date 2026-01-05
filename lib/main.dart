import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'data/repositories/authentication/authentication_repository.dart';
import 'firebase_options.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';

/// -- Entry Point de Flutter App
Future<void> main() async {

  /// Widgets Binding
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX Local Storage
  await GetStorage.init();

  /// -- Esperar a Splash cargue otros elementos
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// -- Inicializar Firebase y Authentication Repository
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then(
      (FirebaseApp value) => Get.put(AuthenticationRepository()),
  );


  // Cargar todos los materiales Diseño / Temas / Localizacions / Ofertas
  runApp(const App());
}

