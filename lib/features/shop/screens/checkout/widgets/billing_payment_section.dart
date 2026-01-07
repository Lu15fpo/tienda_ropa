import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/checkout_controller.dart';

class TBillingPaymentSection extends StatelessWidget {
  const TBillingPaymentSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CheckoutController());
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      children: [
        TSectionHeading(
          title: 'Método de pago',
          buttonTitle: 'Cambiar',
          onPressed: () => controller.selectPaymentMethod(context),
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),
        Obx(
          () {
            final method = controller.selectedPaymentMethod.value;

            // Si no hay método seleccionado, mostrar mensaje
            if (method.id.isEmpty && method.name.isEmpty) {
              return Text(
                'No hay método de pago seleccionado',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            // Si tiene cardHolderName, es un método guardado (nuevo sistema)
            if (method.cardHolderName != null && method.cardHolderName!.isNotEmpty) {
              return Row(
                children: [
                  /// Badge del tipo de tarjeta
                  TRoundedContainer(
                    width: 60,
                    height: 35,
                    backgroundColor: dark ? TColors.light : TColors.white,
                    padding: const EdgeInsets.all(TSizes.sm),
                    child: Center(
                      child: Text(
                        method.cardType ?? 'Card',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),

                  /// Información de la tarjeta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.maskedCardNumber,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          method.cardHolderName ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Fallback para métodos antiguos (compatibilidad)
            else {
              return Row(
                children: [
                  TRoundedContainer(
                    width: 60,
                    height: 35,
                    backgroundColor: dark ? TColors.light : TColors.white,
                    padding: const EdgeInsets.all(TSizes.sm),
                    child: method.image.isNotEmpty
                        ? Image(
                            image: AssetImage(method.image),
                            fit: BoxFit.contain,
                          )
                        : const Icon(Icons.payment),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    method.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

