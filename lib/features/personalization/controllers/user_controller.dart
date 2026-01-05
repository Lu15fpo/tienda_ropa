import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tienda_ropa/data/repositories/authentication/authentication_repository.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/loaders.dart';
import '../../authentication/models/user_model.dart';
import '../../authentication/screens/login/login.dart';
import '../screens/profile/widgets/re_authenticate_user_login_form.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final profileLoading = false.obs;
  Rx<UserModel> user = UserModel.empty().obs;

  final hidePassword = false.obs;
  final imageUploading = false.obs;
  final verifyEmail = TextEditingController();
  final verifyPassword = TextEditingController();
  final userRepository = Get.put(UserRepository());
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    fetchUserRecord();
  }

  /// Obtener los detalles del usuario
  Future <void> fetchUserRecord() async {
    try {
      profileLoading.value = true;
      final user = await userRepository.fetchUserDetails();
      this.user(user);
    } catch (e) {
      user(UserModel.empty());
    } finally {
      profileLoading.value = false;
    }
  }


  /// Guardar el registro de usuario en cualquier proveedor de registro
  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      // Primero actualizar Rx User y verificar si es que los datos del usario ya estan guardados. Si no almacenar nuevos datos
      await fetchUserRecord();

      // Si el historia no esta almacenado
      if (user.value.id.isEmpty) {
        if(userCredentials != null) {
          // Convertir Nombre a Nombres y Apellidos
          final nameParts = UserModel.nameParts(userCredentials.user!.displayName ?? '');
          final username = UserModel.generateUsername(userCredentials.user!.displayName ?? '');

          // Mapa de Datos
          final user = UserModel (
            id: userCredentials.user!.uid,
            firstName: nameParts[0],
            lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            username: username,
            email: userCredentials.user!.email ?? '',
            phoneNumber: userCredentials.user!.phoneNumber ?? '',
            profilePicture: userCredentials.user!.photoURL ?? '',
          );

          // Guardar los datos de usuario
          await userRepository.saveUserRecord(user);
        }
      }

    } catch (e) {
      TLoaders.warningSnackBar(
        title: 'No se pudo guardar el registro',
        message: 'Algo salio mal cuando se intento guardar tu informacion. Puedes guardar tu informacion en tu Perfil.'
      );
    }
  }

  /// Alerta de Eliminacion de cuenta
  void deleteAccountWarningPopup() {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(TSizes.md),
      title: 'Eliminar Cuenta',
      middleText:
        'Estas seguro de que quieres eliminar tu cuenta de manera permanente? Esta accion no se puede deshacer y todos tus datos se perderan.',
      confirm: ElevatedButton(
        onPressed: () async => deleteUserAccount(),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
        child: const Padding(padding: EdgeInsets.symmetric(horizontal: TSizes.lg), child: Text('Eliminar')),
      ),
      cancel: OutlinedButton(
        child: const Text('Cancelar'),
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
      ),
    );
  }

  /// Eliminar Cuenta
  void deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog('Procesando', TImages.docerAnimation);

      /// Primera re-autenticacion de usuario
      final auth = AuthenticationRepository.instance;
      final provider = auth.authUser.providerData.map((e) => e.providerId).first;
      if (provider.isNotEmpty) {
        // Re-Autenticacion verificacion de Email
        if (provider == 'google.com') {
          await auth.signInWithGoogle();
          await auth.deleteAccount();
          TFullScreenLoader.stopLoading();
          Get.offAll(() => const LoginScreen());
        } else if (provider == 'password') {
          TFullScreenLoader.stopLoading();
          Get.to(() => const ReAuthLoginForm());
        }
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

  /// -- Re-Autenticacion de Usuario despues de eliminar
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      TFullScreenLoader.openLoadingDialog('Procesando', TImages.docerAnimation);

      // Revisar Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!reAuthFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance.reAuthenticateWithEmailAndPassword(verifyEmail.text.trim(), verifyPassword.text.trim());
      await AuthenticationRepository.instance.deleteAccount();
      TFullScreenLoader.stopLoading();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

  /// Subir Imagen de perfil
  Future<void> uploadUserProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxHeight: 512, maxWidth: 512);
      if(image != null){
        imageUploading.value = true;
        // Subir Imagen
        final imageUrl = await userRepository.uploadImage('Users/Images/Profile/', image);

        // Subir Imagen de usuario al almacenamiento
        Map<String, dynamic> json = {'ProfilePicture': imageUrl};
        await userRepository.updateSingleField(json);

        user.value.profilePicture = imageUrl;
        user.refresh();
        TLoaders.successSnackBar(title: 'Felicidades!', message: 'Se actualizo la imagen de tu Perfil');
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: 'Algo salio mal: $e');
    } finally {
      imageUploading.value = false;
    }
  }
}