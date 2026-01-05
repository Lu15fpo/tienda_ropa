import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/helpers/network_manager.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../screens/password_configuration/reset_password.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  /// Variables
  final email = TextEditingController();
  GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  /// Enviar Email de Recuperacion de Contraseña
  Future<void> sendPasswordResetEmail() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Procesando tu solicitud...', TImages.docerAnimation);

      // Revisar la conexion a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected) {TFullScreenLoader.stopLoading(); return;}

      // Validar Formulario
      if (!forgetPasswordFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Enviar Email de restauracion de contraseña
      await AuthenticationRepository.instance.sendPasswordResetEmail(email.text.trim());

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mostrar Mensaje de Exito
      TLoaders.successSnackBar(title: 'Email enviado!', message: 'El Link de recuperacion de contraseña fue enviado a tu correo.'.tr);

      // Redireccionar a la pantalla de login
      Get.to(() => ResetPasswordScreen(email: email.text.trim()));

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

  Future<void> resendPasswordResetEmail(String email) async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Procesando tu solicitud...', TImages.docerAnimation);

      // Revisar la conexion a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected) {TFullScreenLoader.stopLoading(); return;}

      // Enviar Email de restauracion de contraseña
      await AuthenticationRepository.instance.sendPasswordResetEmail(email);

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mostrar Mensaje de Exito
      TLoaders.successSnackBar(title: 'Email enviado!', message: 'El Link de recuperacion de contraseña fue enviado a tu correo.'.tr);

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

}