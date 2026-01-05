import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';

import '../../../../common/widgets/products/sortable/sortable_products.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/cloud_helper_functions.dart';
import '../../controllers/all_products_controller.dart';
import '../../models/product_model.dart';

class AllProducts extends StatelessWidget {
  const AllProducts({super.key, required this.title, this.query, this.futureMethod});

  final String title;
  final Query? query;
  final Future<List<ProductModel>>? futureMethod;

  @override
  Widget build(BuildContext context) {
    // Incializar controlador para el manejo de productos
    final controller = Get.put(AllProductsController());

    return Scaffold(
      /// AppBar
      appBar: TAppBar(title: Text(title), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: FutureBuilder(
            future: futureMethod ?? controller.fetchProductsByQuery(query),
            builder: (context, snapshot) {
              // Revisar el estado de FutureBuilder
              const loader = TVerticalProductShimmer();
              final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader);

              // Retornar un widget apropiado basado en el estado de la instantanea
              if (widget != null) return widget;

              // Productos encontrados!
              final products = snapshot.data!;

              return TSortableProducts(products: products);
            }
          ),
        ),
      ),
    );
  }
}

