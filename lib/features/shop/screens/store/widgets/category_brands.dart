import 'package:flutter/cupertino.dart';
import 'package:tienda_ropa/common/widgets/brands/brand_show_case.dart';
import 'package:tienda_ropa/features/shop/controllers/brand_controller.dart';
import 'package:tienda_ropa/features/shop/models/category_model.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';

import '../../../../../common/widgets/shimmers/boxes_shimmer.dart';
import '../../../../../common/widgets/shimmers/list_tile_shimmer.dart';
import '../../../../../utils/constants/sizes.dart';

class CategoryBrands extends StatelessWidget {
  const CategoryBrands({
    super.key,
    required this.category
  });

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final controller = BrandController.instance;
    return FutureBuilder(
      future: controller.getBrandsForCategory(category.id),
      builder: (context, snapshot) {

        /// Manejo del Loader, No Record, o mensaje de error
        const loader = Column(
          children: [
            TListTileShimmer(),
            SizedBox(height: TSizes.spaceBtwItems),
            TBoxesShimmer(),
            SizedBox(height: TSizes.spaceBtwItems)
          ],
        );

        final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);
        if (widget != null) return widget;

        /// Historial Encontrado!
        final brands = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: brands.length,
          itemBuilder: (_, index) {
            final brand = brands[index];
            return FutureBuilder(
              future: controller.getBrandProducts(brandId: brand.id, limit: 3),
              builder: (context, snapshot) {

                /// Manejo del Loader, No Record, o mensaje de error
                final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);
                if (widget != null) return widget;

                /// Historial Encontrado!
                final products = snapshot.data!;

                return TBrandShowcase(brand: brand, images: products.map((e) => e.thumbnail).toList());
              }
            );
          },
        );
      }
    );
  }
}