import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/user/user_repository.dart';
import '../../../../utils/helpers/network_manager.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/user_model.dart';
import '../../screens/signup/verify_email.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs;    // Variable para ocultar contraseña
  final privacyPolicy = true.obs;   // Variable para aceptar politicas de privacidad
  final email = TextEditingController();  // Controlador de email
  final lastName = TextEditingController();   // Controlador para Apellido
  final username = TextEditingController();   // Controlador para Nombre de Usuario
  final password = TextEditingController();   // Controlador para Contraseña
  final firstName = TextEditingController();    // Controlador para Nombre
  final phoneNumber = TextEditingController();    // Controlador para Numero de Telefono
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();    // Form key para validar formulario

  /// -- SIGNUP
  void signup() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Estamos procesando tu informacion...', TImages.docerAnimation);

      // Revisar la conexion a Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Eliminar Carga
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validacion del formulario
      if (!signupFormKey.currentState!.validate()) {
        // Eliminar Carga
        TFullScreenLoader.stopLoading();
        return;
      }

      // Privacidad de Politicas Check
      if (!privacyPolicy.value) {
        TLoaders.warningSnackBar(
          title: 'Acepte Privacy Policy',
          message: 'Para continuar, lea y acepte las politicas de privacidad'
        );
        return;
      }

      // Registrar Usuario en Firebase Authentication y guardar los datos en Firebase
      final userCredential = await AuthenticationRepository.instance.registerWithEmailAndPassword(email.text.trim(), password.text.trim());

      // Guardar usuario autenticado en Firebase Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        username: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: '',
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mostrar mensaje de confirmacion
      TLoaders.successSnackBar(title: 'Felicidades!', message: 'Tu cuenta ha sido creada con exito! Verifica tu email para continuar.');

      // Redireccionar a pantalla de Verificacion de Email
      Get.to(() => VerifyEmailScreen(email: email.text.trim(),));
    } catch (e) {
      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mostrar un Error generico al usuario
      TLoaders.errorSnackBar(title: 'Vaya! Algo salio mal', message: e.toString());
    }
  }
}