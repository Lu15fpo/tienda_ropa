import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tienda_ropa/common/styles/shadows.dart';
import 'package:tienda_ropa/common/widgets/images/t_rounded_image.dart';
import 'package:tienda_ropa/common/widgets/products/favourite_icon/favourite_icon.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/product_detail.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import '../../../../features/shop/controllers/product/product_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../custom_shapes/containers/rounded_container.dart';
import '../../texts/product_price_text.dart';
import '../../texts/product_title_text.dart';
import '../../texts/t_brand_title_text_with_verified_icon.dart';
import 'add_to_cart_button.dart';

class TProductCardVertical extends StatelessWidget {
  const TProductCardVertical({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    final salePercentage = controller.calculateSalePercentage(product.price, product.salePrice);
    final dark = THelperFunctions.isDarkMode(context);

    /// Container con paddings, color, esquinas, radios y sombras
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [TShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(TSizes.productImageRadius),
          color: dark ? TColors.darkerGrey : TColors.white,
        ),
        child: Column(
          children: [
            /// Miniatura del producto, Boton de Favoritos, Icono de descuento
            TRoundedContainer(
              height: 180,
              width: 180,
              padding: const EdgeInsets.all(TSizes.sm),
              backgroundColor: dark ? TColors.dark : TColors.light,
              child: Stack(
                children: [
                  /// -- Miniatura del producto
                  Center(child: TRoundedImage(imageUrl: product.thumbnail, applyImageRadius: true, isNetworkImage: true)),
      
                  /// -- Tag Venta
                  if (salePercentage != null)
                    Positioned(
                      top: 12,
                      child: TRoundedContainer(
                        radius: TSizes.sm,
                        backgroundColor: TColors.secondary.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                        child: Text('$salePercentage%', style: Theme.of(context).textTheme.labelLarge!.apply(color: TColors.black)),
                      ),
                    ),
      
                  /// -- Boton de Favoritos
                  Positioned(
                      top: 0,
                      right: 0,
                      child: TFavouriteIcon(productId: product.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
      
            /// -- Detalles del producto
            Padding(
              padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TProductTitleText(title: product.title, smallSize: true),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    TBrandTitleWithVerifiedIcon(title: product.brand!.name),
                  ],
                ),
              ),
            ),

            // Agregar Spacer() aqui para mantener el espacio entre los textos de las cajas
            const Spacer(),

            /// -- Precio Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Precio
                Flexible(
                  child: Column(
                    children: [
                      if (product.productType == ProductType.single.toString() && product.salePrice > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: TSizes.sm),
                          child: Text(
                            product.price.toString(),
                            style: Theme.of(context).textTheme.labelMedium!.apply(decoration: TextDecoration.lineThrough),
                          )
                        ),


                      /// Precio, mostrar descuento si existe
                      Padding(
                        padding: const EdgeInsets.only(left: TSizes.sm),
                        child: TProductPriceText(price: controller.getProductPrice(product)),
                      ),
                    ],
                  ),
                ),

                /// Boton de Agregar al carrito
                ProductCardAddToCartButton(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



