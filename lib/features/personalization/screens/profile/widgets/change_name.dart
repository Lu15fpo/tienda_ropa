import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/utils/validators/validation.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../controllers/update_name_controller.dart';

class ChangeName extends StatelessWidget {
  const ChangeName({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateNameController());
    return Scaffold(
      /// Appbar Custom
      appBar: TAppBar(
        showBackArrow: true,
        title: Text('Cambiar Nombre', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Encabezado
            Text(
              'Usa un nombre real para una verificacion facil. Este nombre aparecera en varias paginas.',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Campo de texto y boton
            Form(
              key: controller.updateUserNameFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.firstName,
                    validator: (value) => TValidator.validateEmptyText('Nombres', value),
                    expands: false,
                    decoration: const InputDecoration(labelText: TTexts.firstName, prefixIcon: Icon(Iconsax.user)),
                  ),
                  const SizedBox(height: TSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.lastName,
                    validator: (value) => TValidator.validateEmptyText('Apellidos', value),
                    expands: false,
                    decoration: const InputDecoration(labelText: TTexts.lastName, prefixIcon: Icon(Iconsax.user)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Boton de Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => controller.updateUserName(), child: const Text('Guardar')),
            ),
          ],
        ),
      ),
    );
  }
}