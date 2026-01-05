import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/utils/constants/text_strings.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/signup/verify_email_controller.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());

    return Scaffold(
      /// El icono de cerrar en la app bar es usado para cerrar sesion y redirecciona a la pantalla de Login.
      /// Este proceso se usa para manejar escenarios donde el usuario entra al proceso de registro
      /// y los datos son almacenados. Al abrir la app, esta revisa si el email ya fue verificado
      /// Si no fue verificado, la app siempre redigira al usuario a la pantalla de Verificacion de Email

      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [IconButton(onPressed: () => AuthenticationRepository.instance.logout(), icon: const Icon(CupertinoIcons.clear))],
      ),
      body: SingleChildScrollView(
        // Padding para dar por defecto espacios iguales en todos los lados de la pantalla
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Imagen
              Image(
                  image: const AssetImage(TImages.deliveredEmailIllustration),
                  width: THelperFunctions.screenWidth() * 0.6
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Titulo y SubTitulo
              Text(TTexts.confirmEmail, style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(email ?? '', style: Theme
                  .of(context)
                  .textTheme
                  .labelLarge, textAlign: TextAlign.center),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(TTexts.confirmEmailSubTitle, style: Theme
                  .of(context)
                  .textTheme
                  .labelMedium, textAlign: TextAlign.center),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Botones
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => controller.checkEmailVerificationStatus(),
                      child: const Text(TTexts.tContinue)
                  )
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              SizedBox(width: double.infinity, child: TextButton(onPressed: () => controller.sendEmailVerification(), child: const Text(TTexts.resendEmail))),

            ],
          ),
        ),
      ),
    );
  }


}