import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tienda_ropa/data/repositories/authentication/authentication_repository.dart';
import 'package:tienda_ropa/utils/helpers/network_manager.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../../utils/constants/image_strings.dart';
import '../../../personalization/controllers/user_controller.dart';

class LoginController extends GetxController {

  /// Variables
  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final userController = Get.put(UserController());

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    super.onInit();
  }

  /// -- Email y Contraseña Inicio de Sesion
  Future<void> emailAndPasswordSignIn() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Iniciando sesion...', TImages.docerAnimation);

      // Revisar Conexion a Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validacion de Formulario
      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Guardar datos de inicio de sesion si esta seleccionado
      if(rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      // Inicio de sesion usando Email y Contraseña Authentication
      final userCredentials = await AuthenticationRepository.instance.loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      // Guardar/Verificar datos de usuario
      await userController.saveUserRecord(userCredentials);

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Redireccionar
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

  /// -- Inicione Sesion con Google
  Future<void> googleSignIn() async {
    try {
      // Empezar la Carga
      TFullScreenLoader.openLoadingDialog('Iniciando sesion...', TImages.docerAnimation);

      // Revisar Conexion a Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Google Authentication
      final userCredentials = await AuthenticationRepository.instance.signInWithGoogle();

      // Guardar Datos de Usuario
      await userController.saveUserRecord(userCredentials);

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Redireccionar
      AuthenticationRepository.instance.screenRedirect();

    } catch (e) {
      // Eliminar Carga
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }
}