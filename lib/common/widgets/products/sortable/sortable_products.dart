import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../features/shop/controllers/all_products_controller.dart';
import '../../../../features/shop/models/product_model.dart';
import '../../../../utils/constants/sizes.dart';
import '../../layouts/grid_layout.dart';
import '../product_cards/product_card_vertical.dart';

class TSortableProducts extends StatelessWidget {
  const TSortableProducts({
    super.key, required this.products,
  });

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    // Incializar controlador para el manejo de productos
    final controller = Get.put(AllProductsController());
    controller.assignProducts(products);

    return Column(
      children: [
        /// Desplegar
        DropdownButtonFormField(
          decoration: const InputDecoration(prefixIcon: Icon(Iconsax.sort)),
          initialValue: controller.selectedSortOption.value,
          onChanged: (value) {
            // Mostrar productos basado en la opcion seleccionada
            controller.sortProducts(value!);
          },
          items: ['Nombre', 'Max. Precio', 'Min. Precio', 'Oferta', 'Recientes', 'Popularidad']
              .map((option) => DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),

        /// Productos
        Obx(() => TGridLayout(itemCount: controller.products.length, itemBuilder: (_, index) => TProductCardVertical(product: controller.products[index]))),
      ],
    );
  }
}
