import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/layouts/grid_layout.dart';
import 'package:tienda_ropa/features/shop/screens/brand/brand_products.dart';

import '../../../../common/widgets/brands/brand_card.dart';
import '../../../../common/widgets/shimmers/brands_shimmer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/brand_controller.dart';

class AllBrandsScreen extends StatelessWidget {
  const AllBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandController = BrandController.instance;
    return Scaffold(
      appBar: const TAppBar(title: Text('Marcas'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Encabezado
              const TSectionHeading(title: 'Marcas', showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- Marcas
              /// -- GRID Marcas
              Obx(() {
                if (brandController.isLoading.value) return const TBrandsShimmer();

                if (brandController.allBrands.isEmpty) {
                  return Center(child: Text('No se encontro datos!', style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.white)));
                }
                return TGridLayout(
                  itemCount: brandController.allBrands.length,
                  mainAxisExtent: 80,
                  itemBuilder: (_, index) {
                    final brand = brandController.allBrands[index];
                    return TBrandCard(showBorder: true, brand: brand, onTap: () => Get.to(() => BrandProducts(brand: brand)));
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
