import 'package:get/get.dart';
import 'package:tienda_ropa/data/repositories/product_repository.dart';
import 'package:tienda_ropa/features/shop/models/brand_model.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../data/repositories/brands/brand_repository.dart';
import '../models/product_model.dart';

class BrandController extends GetxController {
  static BrandController get instance => Get.find();

  RxBool isLoading = true.obs;
  final RxList<BrandModel> allBrands = <BrandModel>[].obs;
  final RxList<BrandModel> featuredBrands = <BrandModel>[].obs;
  final brandRepository = Get.put(BrandRepository());

  @override
  void onInit() {
    getFeaturedBrands();
    super.onInit();
  }

  /// -- Cargar Marcas
  Future<void> getFeaturedBrands() async {
    try {
      // Mostrar carga que cargara las Marcas
      isLoading.value = true;

      final brands = await brandRepository.getAllBrands();

      allBrands.assignAll(brands);

      featuredBrands.assignAll(allBrands.where((brand) => brand.isFeatured ?? false).take(4));


    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    } finally {
      // Detener Carga
      isLoading.value = false;
    }
  }

  /// -- Obtener marcas por categoria
  Future<List<BrandModel>> getBrandsForCategory(String categoryId) async {
    try {
      final brands = await brandRepository.getBrandsForCategory(categoryId);
      return brands;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }

  /// Obtner un producto especifico de la marca desde los datos tus recursos
  Future<List<ProductModel>> getBrandProducts({required String brandId, int limit = -1}) async {
    try {
      final products = await ProductRepository.instance.getProductsForBrand(brandId: brandId, limit: limit);
      return products;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }

  }

  /// Recalcular contadores de productos para todas las marcas
  Future<void> recalculateBrandProductCounts() async {
    try {
      await brandRepository.recalculateAllBrandProductCounts();
      // Recargar las marcas para mostrar los nuevos contadores
      await getFeaturedBrands();
      TLoaders.successSnackBar(title: 'Éxito', message: 'Contadores actualizados correctamente');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }

}