import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/login_signup/social_buttons.dart';
import 'package:tienda_ropa/features/authentication/screens/signup/widgets/signup_form.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import '../../../../common/widgets/login_signup/form_divider.dart';
import '../../../../utils/constants/text_strings.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Titulo
              Text(TTexts.signupTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Form
              const TSignupForm(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Divisor
              TFormDivider(dividerText: TTexts.orSignUpWith.capitalize!),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Botones de redes sociales
              const TSocialButtons(),
              const SizedBox(height: TSizes.spaceBtwItems),

            ],
          ),
        ),
      ),
    );
  }
}

