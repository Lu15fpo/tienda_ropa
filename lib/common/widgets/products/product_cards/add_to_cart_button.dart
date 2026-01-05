import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/features/shop/controllers/product/cart_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/product_detail.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class ProductCardAddToCartButton extends StatelessWidget {
  const ProductCardAddToCartButton({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    return InkWell(
      onTap: () {
        // Si el producto tiene variaciones entonces muestra los detalles de las variaciones seleccionadas
        // Si no añade el producto al carrito
        if (product.productType == ProductType.single.toString()) {
          final cartItem = cartController.convertToCartItem(product, 1);
          cartController.addOneToCart(cartItem);
        } else {
          Get.to(() => ProductDetailScreen(product: product));
        }
      },
      child: Obx(() {

        final productQuantityInCart = cartController.getProductQuantityInCart(product.id);
        return Container(
          decoration: BoxDecoration(
            color: productQuantityInCart > 0 ? TColors.primary : TColors.dark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(TSizes.cardRadiusMd),
              bottomRight: Radius.circular(TSizes.productImageRadius),
            ),
          ),
          child: SizedBox(
            width: TSizes.iconLg * 1.2,
            height: TSizes.iconLg * 1.2,
            child: Center(
              child: productQuantityInCart > 0
                  ? Text(productQuantityInCart.toString(), style: Theme.of(context).textTheme.bodyLarge!.apply(color: TColors.white))
                  : const Icon(Iconsax.add, color: TColors.white),
            ),
          ),
        );
      }),
    );
  }
}
