import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/utils/validators/validation.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/update_cedula_controller.dart';

class ChangeCedula extends StatelessWidget {
  const ChangeCedula({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateCedulaController());
    return Scaffold(
      /// Appbar Custom
      appBar: TAppBar(
        showBackArrow: true,
        title: Text('Agregar/Editar Cédula', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Encabezado
            Text(
              'Ingresa tu cédula o RUC para la facturación electrónica. Este dato es necesario para generar facturas válidas ante el SRI.',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Campo de texto y boton
            Form(
              key: controller.updateCedulaFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.cedula,
                    validator: (value) => TValidator.validateCedula(value),
                    expands: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13), // Máximo 13 dígitos para RUC
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Cédula o RUC',
                      prefixIcon: Icon(Iconsax.card),
                      hintText: '10 dígitos (cédula) o 13 dígitos (RUC)',
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  /// Información sobre el formato
                  Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(TSizes.sm),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.info_circle, size: 20, color: Colors.blue),
                        const SizedBox(width: TSizes.sm),
                        Expanded(
                          child: Text(
                            'Cédula: 10 dígitos\nRUC: 13 dígitos',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Boton de Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.updateCedula(),
                child: const Text('Guardar')
              ),
            ),
          ],
        ),
      ),
    );
  }
}

