import 'package:flutter/material.dart';
import 'package:tienda_ropa/utils/helpers/pricing_calculator.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/cart_controller.dart';

class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    final subTotal = cartController.totalCartPrice.value;
    return Column(
      children: [
        /// Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
            Text('\$$subTotal', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),

        /// Costo de envio
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Envio', style: Theme.of(context).textTheme.bodyMedium),
            Text('\$${TPricingCalculator.calculateShippingCost(subTotal, 'ECU')}', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),

        /// IVA
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('I.V.A', style: Theme.of(context).textTheme.bodyMedium),
            Text('\$${TPricingCalculator.calculateTax(subTotal, 'ECU')}', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems / 2),

        /// Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: Theme.of(context).textTheme.bodyMedium),
            Text('\$${TPricingCalculator.calculateTotalPrice(subTotal, 'ECU')}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),

      ],
    );
  }
}