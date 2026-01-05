import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:tienda_ropa/common/widgets/texts/product_price_text.dart';
import 'package:tienda_ropa/common/widgets/texts/product_title_text.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/shop/controllers/product/variation_controller.dart';

import '../../../../../common/widgets/chips/choice_chip.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/product_model.dart';

class TProductAttributes extends StatelessWidget {
  const TProductAttributes({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VariationController());
    final dark = THelperFunctions.isDarkMode(context);
    
    return Obx(
      () => Column(
        children: [
          /// - Seleccion de atributos de precio y descripcion
          // Desplegar variacion precio y stock cuando alguna variacion sea seleccionada
          if (controller.selectedVariation.value.id.isNotEmpty)
          TRoundedContainer(
            padding: const EdgeInsets.all(TSizes.md),
            backgroundColor: dark ? TColors.darkerGrey : TColors.grey,
            child: Column(
              children: [
                /// Titulo, precio y status del stock
                Row(
                  children: [
                    const TSectionHeading(title: 'Variaciones', showActionButton: false),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TProductTitleText(title: 'Precio', smallSize: true),
      
                            /// Precio actual
                            if (controller.selectedVariation.value.salePrice > 0)
                            Text(
                                '\$${controller.selectedVariation.value.price}',
                                style: Theme.of(context).textTheme.titleSmall!.apply(decoration: TextDecoration.lineThrough)
                            ),
                            const SizedBox(width: TSizes.spaceBtwItems),
      
                            /// Precio de descuento
                            TProductPriceText(price: controller.getVariationPrice()),
                          ],
                        ),
      
                        /// Stock
                        Row(
                          children: [
                            const TProductTitleText(title: 'Stock: ', smallSize: true),
                            Text(controller.variationStockStatus.value, style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
      
                /// Descripcion de variaciones
                TProductTitleText(
                  title: controller.selectedVariation.value.description ?? '',
                  smallSize: true,
                   maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
      
          /// -- Atributos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: product.productAttributes!
                .map((attribute) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TSectionHeading(
                            title: attribute.name ?? '', showActionButton: false),
                        const SizedBox(height: TSizes.spaceBtwItems / 2),
                        Obx(
                          () => Wrap(
                              spacing: 8,
                              children: attribute.values!.map((attributeValue) {
                                final isSelected =
                                    controller.selectedAttributes[attribute.name] ==
                                        attributeValue;
                                final available = controller
                                    .getAttributesAvailabilityInVariation(
                                        product.productVariations!, attribute.name!)
                                    .contains(attributeValue);
                          
                                return TChoiceChip(
                                    text: attributeValue,
                                    selected: isSelected,
                                    onSelected: available
                                        ? (selected) {
                                            if (selected && available) {
                                              controller.onAttributeSelected(
                                                  product,
                                                  attribute.name ?? '',
                                                  attributeValue);
                                            }
                                          }
                                        : null);
                              }).toList()),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

