import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/personalization/controllers/user_controller.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/helpers/network_manager.dart';
import '../screens/profile/profile.dart';

class UpdateNameController extends GetxController {
  static UpdateNameController get instance => Get.find();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final userController = UserController.instance;
  final userRepository = Get.put(UserRepository());
  GlobalKey <FormState> updateUserNameFormKey = GlobalKey<FormState>();

  /// Inicializar informacion de usuario cuando la pantalla Home aparezca
  @override
  void onInit() {
    initializeNames();
    super.onInit();
  }

  /// Obtener registro de usuario
  Future<void> initializeNames() async {
    firstName.text = userController.user.value.firstName;
    lastName.text = userController.user.value.lastName;
  }

  Future<void> updateUserName() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Estamos actualizando tu informacion...', TImages.docerAnimation);

      // Revisar conexion a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validacion de formulario
      if (!updateUserNameFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Actualizar Nombre y Apellidos en Firebase Firestore
      Map<String, dynamic> name = {'Nombres': firstName.text.trim(), 'Apellidos': lastName.text.trim()};
      await userRepository.updateSingleField(name);

      // Actualizar el valor de Rx User
      userController.user.value.firstName = firstName.text.trim();
      userController.user.value.lastName = lastName.text.trim();

      // Cerrar Carga
      TFullScreenLoader.stopLoading();

      // Mostrar mensaje de exito
      TLoaders.successSnackBar(title: 'Felicidades!', message: 'Tu nombre ha sido actualizado con exito.');

      // Regresar a la pantalla anterior
      Get.off(() => const ProfileScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }
}