import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/shop/models/category_model.dart';
import 'package:tienda_ropa/features/shop/screens/store/widgets/category_brands.dart';

import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/cloud_helper_functions.dart';
import '../../../controllers/category_controller.dart';
import '../../all_products/all_products.dart';

class TCategoryTab extends StatelessWidget {
  const TCategoryTab({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryController.instance;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [

              /// -- Marcas
              CategoryBrands(category: category),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Productos
              FutureBuilder(
                future: controller.getCategoryProducts(categoryId: category.id),
                builder: (context, snapshot) {

                  /// Funcion de ayuda: Manejar la carga, sin record, o mensaje de error
                  final response = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: const TVerticalProductShimmer());
                  if (response != null) return response;

                  /// Encontramos historial!
                  final products = snapshot.data!;

                  return Column(
                    children: [
                      TSectionHeading(
                        title: 'Te podria interesar',
                        onPressed: () => Get.to(
                            AllProducts(
                              title: category.name,
                              futureMethod: controller.getCategoryProducts(categoryId: category.id, limit: -1),
                            ),
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      TGridLayout(itemCount: products.length, itemBuilder: (_, index) => TProductCardVertical(product: products[index])),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ]
    );
  }
}