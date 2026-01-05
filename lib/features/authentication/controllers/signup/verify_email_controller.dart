import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/utils/constants/text_strings.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../../common/widgets/success_screen/success_screen.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/image_strings.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  /// Enviar al Email la verificacion cuando el usuario se registre y establecer un temporizador para autoredireccionar
  @override
  void onInit() {
    sendEmailVerification();
    setTimerForAutoRedirect();
    super.onInit();
  }

  /// Enviar link de verificacion al email
  Future<void> sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      TLoaders.successSnackBar(title: 'Email Enviado', message: 'Por favor revisa tu bandeja y verifica tu email.');
    }catch(e){
      TLoaders.errorSnackBar(title: 'Vaya! Algo salio mal', message: e.toString());
    }
  }
  /// Temporizador para automaticamente redireccionar a la Verificacion de Email
  void setTimerForAutoRedirect() {
    Timer.periodic(
        const Duration(seconds: 1),
          (timer) async {
          await FirebaseAuth.instance.currentUser?.reload();
          final user = FirebaseAuth.instance.currentUser;
          if(user?.emailVerified ??  false) {
            timer.cancel();
            Get.off(
                () => SuccessScreen(
                  image: TImages.successfullyRegisterAnimation,
                  title: TTexts.yourAccountCreatedTitle,
                  subTitle: TTexts.yourAccountCreatedSubTitle,
                  onPressed: () => AuthenticationRepository.instance.screenRedirect(),
                ),
            );
          }
        },
    );
  }

  /// Revision de manera manual si el Email fue verificado
  Future<void> checkEmailVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(
          () => SuccessScreen(
            image: TImages.successfullyRegisterAnimation,
            title: TTexts.yourAccountCreatedTitle,
            subTitle: TTexts.yourAccountCreatedSubTitle,
            onPressed: () => AuthenticationRepository.instance.screenRedirect(),
          ),
      );
    }
  }
}