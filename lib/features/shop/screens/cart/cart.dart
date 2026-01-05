import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/loaders/animation_loader.dart';
import 'package:tienda_ropa/features/shop/screens/cart/widgets/cart_items.dart';

import '../../../../navigation_menu.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/product/cart_controller.dart';
import '../checkout/checkout.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    return Scaffold(
      appBar: TAppBar(showBackArrow: true, title: Text('Carrito', style: Theme.of(context).textTheme.headlineSmall)),
      body: Obx(
        () {

          /// No se encontro nada Widget
          final emptyWidget = TAnimationLoaderWidget(
            text: 'Oooops! No hay nada en el carrito.',
            animation: TImages.cartAnimation,
            showAction: true,
            actionText: 'Vamos a la tienda',
            onActionPressed: () => Get.off(() => const NavigationMenu()),
          );

          if (controller.cartItems.isEmpty) {
            return emptyWidget;
          } else {
            return const SingleChildScrollView(
              child: Padding(
                    padding: EdgeInsets.all(TSizes.defaultSpace),
              
                    /// -- Productos en el carrito
                    child: TCartItems(enableScroll: true),
                ),
            );
          }
        },
      ),

      /// Boton de pagar
      bottomNavigationBar: controller.cartItems.isEmpty
          ? const SizedBox()
          : Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: ElevatedButton(
                  onPressed: () => Get.to(() => const CheckoutScreen()),
                  child: Obx(() =>
                      Text('Pagar \$${controller.totalCartPrice.value}'))),
            ),
    );
  }
}

