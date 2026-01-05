import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/routes/app_routes.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/theme/theme.dart';
import 'bindings/general_bindings.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialBinding: GeneralBindings(),
      getPages: AppRoutes.pages,
      /// Mostrar Cargador o  Indicador de Progreso Circular mientras Authentication Repositorio carga los datos para mostrar la pantalla de inicio
      home: const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white),),),
    );
  }
}