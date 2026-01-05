import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../../data/repositories/product_repository.dart';
import '../../../../utils/constants/enums.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  final isLoading = false.obs;
  final productRepository = Get.put(ProductRepository());
  RxList<ProductModel> featuredProducts = <ProductModel>[].obs;

  @override
  void onInit() {
    fetchFeaturedProducts();
    super.onInit();
  }

  void fetchFeaturedProducts() async {
    try {
      // Mostrar cargador cuando se esten cargando los Productos
      isLoading.value = true;

      // Obtener los productos
      final products = await productRepository.getFeaturedProducts();

      // Assignar Productos
      featuredProducts.assignAll(products);

    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ProductModel>> fetchAllFeaturedProducts() async {
    try {
      // Obtener los productos
      final products = await productRepository.getFeaturedProducts();
      return products;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }

  /// Obtener el precio del producto o el rango de precio por variacion.
  String getProductPrice(ProductModel product) {
    double smallestPrice = double.infinity;
    double largestPrice = 0.0;

    // Si no existen variaciones, retornar el precio del producto o el precio de descuento
    if (product.productType == ProductType.single.toString()) {
      return (product.salePrice > 0 ? product.salePrice : product.price).toString();
    } else {
      // Calcular los precios minimos y maximos de las variaciones
      for (var variation in product.productVariations!) {
        // Determinar el precio considerado (precio de descuento o precio normal)
        double priceToConsider = variation.salePrice > 0.0 ? variation.salePrice : variation.price;

        // Actualizar el precio minimo y maximo
        if(priceToConsider < smallestPrice) {
          smallestPrice = priceToConsider;
        }

        if(priceToConsider > largestPrice) {
          largestPrice = priceToConsider;
        }
      }

      // Si el precio minimo y maximo son iguales, retornar el precio del producto
      if(smallestPrice.isEqual(largestPrice)) {
        return largestPrice.toString();
      } else {
        // Retornar el rango de precios
        return '$smallestPrice - \$largestPrice';
      }
    }
  }

  /// -- Calcular Porcentaje de Descuento
  String? calculateSalePercentage(double originalPrice, double? salePrice) {
    if(salePrice == null || salePrice <= 0.0) return null;
    if (originalPrice <= 0) return null;

    double percentage = ((originalPrice - salePrice) / originalPrice) * 100;
    return percentage.toStringAsFixed(0);
  }

  /// -- Revisar Stock de Producto
  String getProductStockStatus(int stock) {
    return stock > 0 ? 'En Stock' : 'Fuera de Stock';
  }
}