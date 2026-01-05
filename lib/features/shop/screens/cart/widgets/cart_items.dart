import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/products/cart/add_remove_button.dart';
import '../../../../../common/widgets/products/cart/cart_item.dart';
import '../../../../../common/widgets/texts/product_price_text.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/cart_controller.dart';

class TCartItems extends StatelessWidget {
  const TCartItems({
    super.key,
    this.showAddRemoveButtons = true,
    this.enableScroll = true
  });

  final bool showAddRemoveButtons;
  final bool enableScroll;

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    return Obx(
      () => ListView.separated(
        shrinkWrap: true,
        physics: enableScroll ? null : const NeverScrollableScrollPhysics(),
        itemCount: cartController.cartItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: TSizes.spaceBtwSections),
        itemBuilder: (_, index) => Obx(
          () {
            final item = cartController.cartItems[index];
            return Column(
              children: [
                /// Items del carrito
                TCartItem(cartItem: item),
                if (showAddRemoveButtons)
                  const SizedBox(height: TSizes.spaceBtwItems),

                /// Agregar y quitar cantidad con el precio total
                if (showAddRemoveButtons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          /// Espacio Extra
                          const SizedBox(width: 70),

                          /// Boton de eliminar y aumentar
                          TProductQuantityWithAddRemoveButton(
                            quantity: item.quantity,
                            add: () => cartController.addOneToCart(item),
                            remove: () => cartController.removeOneFromCart(item),
                          ),
                        ],
                      ),

                      /// -- Precio total
                      TProductPriceText(price: (item.price * item.quantity).toStringAsFixed(1)),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}