import 'package:flutter/material.dart';
import 'package:tienda_ropa/common/widgets/images/t_circular_image.dart';
import 'package:tienda_ropa/common/widgets/texts/product_price_text.dart';
import 'package:tienda_ropa/common/widgets/texts/product_title_text.dart';
import 'package:tienda_ropa/common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import 'package:tienda_ropa/features/shop/controllers/product/product_controller.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../models/product_model.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({
    super.key, required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProductController.instance;
    final salePercentage = controller.calculateSalePercentage(product.price, product.salePrice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Precio y Descuento
        Row(
          children: [
            /// Etiqueta de descuento - solo mostrar si hay descuento
            if(salePercentage != null && salePercentage.isNotEmpty && salePercentage != '0')
              TRoundedContainer(
                radius: TSizes.sm,
                backgroundColor: TColors.secondary.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                child: Text('$salePercentage%', style: Theme.of(context).textTheme.labelLarge!.apply(color: TColors.black)),
              ),
            if(salePercentage != null && salePercentage.isNotEmpty && salePercentage != '0') const SizedBox(width: TSizes.spaceBtwItems),

            /// Precio
            if(product.productType == ProductType.single.toString() && product.salePrice > 0)
              Text('\$${product.price}', style: Theme.of(context).textTheme.titleSmall!.apply(decoration: TextDecoration.lineThrough)),
            if(product.productType == ProductType.single.toString() && product.salePrice > 0) const SizedBox(width: TSizes.spaceBtwItems),
            TProductPriceText(price: controller.getProductPrice(product), isLarge: true),


          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Titulo
        Text(
          product.title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Status de Stock
        Row(
          children: [
            const TProductTitleText(title: 'Estado'),
            const SizedBox(width: TSizes.spaceBtwItems),
            Text(controller.getProductStockStatus(product.stock), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(width: TSizes.spaceBtwItems / 1.5),


        /// Marca
        Row(
          children: [
            TCircularImage(
                image: product.brand != null ? product.brand!.image : '',
                width: 32,
                height: 32,
                isNetworkImage: true
            ),
            TBrandTitleWithVerifiedIcon(title: product.brand != null ? product.brand!.name : '', brandTextSize: TextSizes.medium),
          ],
        ),
      ],
    );
  }
}