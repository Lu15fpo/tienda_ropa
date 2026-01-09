import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// 🔧 CONFIGURACIÓN DE EMULADORES PARA DESARROLLO
  /// Configuración híbrida: Firestore en producción, Functions en emulador
  const bool useFunctionsEmulator = false; // ✅ DESACTIVADO para usar logs detallados en producción

  if (useFunctionsEmulator) {
    // Configurar SOLO Functions Emulator para pruebas de facturación
    // Firestore, Auth y Storage usarán PRODUCCIÓN (datos reales)
    
    // IMPORTANTE: Para dispositivos físicos, usar la IP de tu PC
    // Para emuladores Android, usar 10.0.2.2 (apunta al localhost de tu PC)
    const String emulatorHost = '10.0.2.2'; // Para emulador Android
    // const String emulatorHost = '192.168.X.X'; // Para dispositivo físico (reemplazar con IP real)
    
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator(emulatorHost, 5001);

    print('🔧 [EMULATORS] Configuración híbrida activada:');
    print('   ✅ Functions: EMULADOR ($emulatorHost:5001) - Para pruebas de facturación');
    print('   ✅ Firestore: PRODUCCIÓN - Usando datos reales');
    print('   ✅ Auth: PRODUCCIÓN - Usando usuarios reales');
    print('   ⚠️  Si usas dispositivo físico, cambia emulatorHost a la IP de tu PC');
  } else {
    print('🌐 [PRODUCTION] Usando servicios de producción');
    print('   ✅ Logs detallados habilitados en Firebase Console');
    print('   ✅ Debug en colección "FacturasDebug"');
  }

  Get.put(AuthenticationRepository());

  // Cargar todos los materiales Diseño / Temas / Localizacions / Ofertas
  runApp(const App());
}

