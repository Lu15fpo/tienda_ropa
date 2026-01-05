import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../controllers/login/login_controller.dart';
import '../../password_configuration/forget_password.dart';
import '../../signup/signup.dart';

class TLoginForm extends StatelessWidget {
  const TLoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Form(
      key: controller.loginFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
          child: Column(
            children: [
              /// Email
              TextFormField(
                controller: controller.email,
                validator: (value) => TValidator.validateEmail(value),
                decoration: InputDecoration(
                  prefixIcon: Icon(Iconsax.direct_right),
                  labelText: TTexts.email,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),

              /// Contraseña
              Obx(
                () => TextFormField(
                  validator: (value) => TValidator.validatePassword(value),
                  controller: controller.password,
                  obscureText: controller.hidePassword.value,
                  decoration: InputDecoration(
                      labelText: TTexts.password,
                      prefixIcon: const Icon(Iconsax.password_check),
                      suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                        icon: Icon(controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye),
                      )
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields / 2),

              /// Recuerda mi cuenta y Olvide mi contraseña
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Recuerda mi cuenta
                  Row(
                    children: [
                      Obx(() => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: (value) => controller.rememberMe.value =
                              !controller.rememberMe.value)),
                      const Text(TTexts.rememberMe),
                    ],
                  ),

                  /// Olvide mi contraseña
                  TextButton(
                    onPressed: () => Get.to(() => const ForgetPassword()),
                    child: const Text(TTexts.forgetPassword),
                  )
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Boton de Inicio de Sesion
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => controller.emailAndPasswordSignIn(), child: const Text(TTexts.signIn))),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Boton de Crear Cuenta
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Get.to(() => const SignupScreen()), child: const Text(TTexts.createAccount))),
            ],
          ),
        )
    );
  }
}
