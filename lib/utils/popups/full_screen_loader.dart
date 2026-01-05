import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import '../../common/widgets/loaders/animation_loader.dart';
import '../constants/colors.dart';

/// Clase utilitaria para manejar dialogo de carga en pantalla completa
class TFullScreenLoader{
  /// Abre una pantalla completa de carga de dialogo con una imagen de animacion
  /// Este metodo no returna nada
  ///
  /// Parametros:
  ///   -text: El texto se desplegara en un dialogo de carga
  ///   - animation: El Lottie animation a mostrar
  static void openLoadingDialog(String text, String animation) {
    showDialog(
        context: Get.overlayContext!, // Usa Get.overlayContext para obtener el contexto
        barrierDismissible: false,  // El dialogo no se cerrara al tocar fuera de el
        builder: (_) => PopScope(
            canPop: false,  // Desactiva el pop del dialogo con el boton de regreso
            child: Container(
              color: THelperFunctions.isDarkMode(Get.context!) ? TColors.dark : TColors.white,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 250),  // Ajusta el espacio que se necesite
                  TAnimationLoaderWidget(animation: animation, text: text),
                ],
              ),
            ),
        ),
    );
  }

  /// Detener el actual dialogo de carga
  /// Este metodo no retorna nada
  static void stopLoading() {
    Navigator.of(Get.overlayContext!).pop(); // Cierra el dialogo usando Navigator
  }
}