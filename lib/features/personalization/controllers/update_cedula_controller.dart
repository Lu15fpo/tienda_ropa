import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/personalization/controllers/user_controller.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/helpers/network_manager.dart';
import '../screens/profile/profile.dart';

class UpdateCedulaController extends GetxController {
  static UpdateCedulaController get instance => Get.find();

  final cedula = TextEditingController();
  final userController = UserController.instance;
  final userRepository = Get.put(UserRepository());
  GlobalKey<FormState> updateCedulaFormKey = GlobalKey<FormState>();

  /// Inicializar cédula cuando la pantalla aparezca
  @override
  void onInit() {
    initializeCedula();
    super.onInit();
  }

  /// Obtener cédula actual del usuario
  Future<void> initializeCedula() async {
    cedula.text = userController.user.value.cedula;
  }

  Future<void> updateCedula() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Actualizando tu cédula...', TImages.docerAnimation);

      // Revisar conexion a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validacion de formulario
      if (!updateCedulaFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Actualizar Cédula en Firebase Firestore
      Map<String, dynamic> cedulaData = {'Cedula': cedula.text.trim()};
      await userRepository.updateSingleField(cedulaData);

      // Actualizar el valor de Rx User
      userController.user.value.cedula = cedula.text.trim();

      // Forzar actualización del observable
      userController.user.refresh();

      // Cerrar Carga
      TFullScreenLoader.stopLoading();

      // Mostrar mensaje de exito
      TLoaders.successSnackBar(
        title: '¡Excelente!',
        message: 'Tu cédula/RUC ha sido actualizada. Ahora tus facturas electrónicas incluirán esta información.'
      );

      // Regresar a la pantalla anterior
      Get.off(() => const ProfileScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }
}

