import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:tienda_ropa/features/shop/screens/checkout/widgets/billing_address_section.dart';
import 'package:tienda_ropa/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:tienda_ropa/features/shop/screens/checkout/widgets/billing_payment_section.dart';
import 'package:tienda_ropa/utils/helpers/pricing_calculator.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/cart/coupon_widget.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/cart_controller.dart';
import '../../controllers/product/order_controller.dart';
import '../cart/widgets/cart_items.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    final subTotal = cartController.totalCartPrice.value;
    final orderController = Get.put(OrderController());
    final totalAmount = TPricingCalculator.calculateTotalPrice(subTotal, 'US');

    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: TAppBar(showBackArrow: true, title: Text('Orden de Pago', style: Theme.of(context).textTheme.headlineSmall)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// -- Productos en el carrito
              const TCartItems(showAddRemoveButtons: false, enableScroll: false),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Texto de Cupon de descuento
              TCouponCode(),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// -- Seccion de precio total
              TRoundedContainer(
                showBorder: true,
                padding: const EdgeInsets.all(TSizes.md),
                backgroundColor: dark ? TColors.black : TColors.white,
                child: const Column(
                  children: [
                    /// Precio
                    TBillingAmountSection(),
                    SizedBox(height: TSizes.spaceBtwItems),

                    /// Divisor
                    Divider(),
                    SizedBox(height: TSizes.spaceBtwItems),

                    /// Metodos de Pago
                    TBillingPaymentSection(),
                    SizedBox(height: TSizes.spaceBtwItems),

                    /// Direccion
                    TBillingAddressSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      /// Boton de pagar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: ElevatedButton(
            onPressed: subTotal > 0
            ? () => orderController.processOrder(totalAmount)
            : () => TLoaders.warningSnackBar(title: 'Carrito Vacio', message: 'Agrega articulos en el carrito para proceder'),
            child: Text('Pagar \$$totalAmount'),
        ),
      ),
    );
  }
}

