import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../data/repositories/product_repository.dart';

class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  final repository = ProductRepository.instance;
  final RxString selectedSortOption = 'Nombre'.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  Future<List<ProductModel>> fetchProductsByQuery(Query? query) async {
    try {
      if(query == null) return [];

      final products = await repository.fetchProductsByQuery(query);

      return products;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }

  void sortProducts(String sortOption) {
    selectedSortOption.value = sortOption;

    switch (sortOption) {
      case 'Nombre' :
        products.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Max. Precio' :
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Min. Precio' :
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Recientes' :
        products.sort((a, b) => a.date!.compareTo(b.date!));
        break;
      case 'Oferta' :
        products.sort((a,b ) {
          if (b.salePrice > 0) {
            return b.salePrice.compareTo(a.salePrice);
          } else if (a.salePrice > 0) {
            return -1;
          } else {
            return 1;
          }
        });
        break;
      default:
        // Opcion por defecto : Nombre
        products.sort((a, b) => a.title.compareTo(b.title));
    }
  }

  void assignProducts(List<ProductModel> products) {
    // Asignar productos a la lista de productos 'products'
    this.products.assignAll(products);
    sortProducts('Nombre');
  }
}