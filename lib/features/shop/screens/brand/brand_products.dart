import 'package:flutter/material.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/brands/brand_card.dart';
import 'package:tienda_ropa/common/widgets/shimmers/vertical_product_shimmer.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';

import '../../../../common/widgets/products/sortable/sortable_products.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/brand_controller.dart';
import '../../models/brand_model.dart';

class BrandProducts extends StatelessWidget {
  const BrandProducts({super.key, required this.brand});

  final BrandModel brand;
  
  @override
  Widget build(BuildContext context) {
    final controller = BrandController.instance;
    return Scaffold(
      appBar: TAppBar(title: Text(brand.name)),
      body: SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Detalles de la Marca
              TBrandCard(showBorder: true, brand: brand),
              const SizedBox(height: TSizes.spaceBtwSections),

              FutureBuilder(
                future: controller.getBrandProducts(brandId: brand.id),
                builder: (context, snapshot) {

                  /// Manejar la carga, sin record, o mensaje de error
                  const loader = TVerticalProductShimmer();
                  final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);
                  if (widget != null) return widget;

                  /// Se encontro historial!
                  final brandProducts = snapshot.data!;
                  return TSortableProducts(products: brandProducts);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}