import 'package:get/get.dart';
import 'package:tienda_ropa/data/repositories/product_repository.dart';
import 'package:tienda_ropa/features/shop/models/category_model.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../data/repositories/categories/category_repository.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  final isLoading = false.obs;
  final _categoryRepository = Get.put(CategoryRepository());
  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  RxList<CategoryModel> featuredCategories = <CategoryModel>[].obs;

  @override
  void onInit() {
    fetchCategories();
    super.onInit();
  }

  /// -- Cargar datos de las categorias
  Future<void> fetchCategories() async {
    try {
      // Mostrar la carga de las categorias cargadas
      isLoading.value = true;

      // Obtener los datos de las categorias de los recursos (Firebase, API, etc)
      final categories = await _categoryRepository.getAllCategories();
      print('📦 [CategoryController] Total categorías obtenidas: ${categories.length}');

      // Actualizar la lista de categorias
      allCategories.assignAll(categories);

      // Mostrar detalles de cada categoría
      print('🔍 [CategoryController] Analizando cada categoría:');
      for (var cat in allCategories) {
        print('  📂 "${cat.name}" - IsFeatured: ${cat.isFeatured}, ParentId: "${cat.parentId}", ¿Es padre?: ${cat.parentId.isEmpty}');
      }

      // Filtro de categorias
      print('🔍 [CategoryController] Filtrando categorías destacadas (IsFeatured=true Y ParentId vacío)...');
      final filtered = allCategories.where((category) => category.isFeatured && category.parentId.isEmpty).take(8).toList();
      print('✅ [CategoryController] Categorías destacadas después del filtro: ${filtered.length}');
      if (filtered.isEmpty) {
        print('⚠️ [CategoryController] PROBLEMA: No hay categorías PADRE con IsFeatured=true');
        print('⚠️ [CategoryController] Todas las categorías parecen ser SUBCATEGORÍAS (tienen ParentId)');
      }
      featuredCategories.assignAll(filtered);
    } catch (e) {
      print('❌ [CategoryController] ERROR: $e');
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    } finally {
      // Eliminar la Carga
      isLoading.value = false;
    }
  }
  /// -- Cargar los datos de la categoria seleccionada
  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {
      final subCategories = await _categoryRepository.getSubCategories(categoryId);
      return subCategories;

    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }
  /// Obtener productos de Categoria o Sub-Categoria
  Future<List<ProductModel>> getCategoryProducts({required String categoryId, int limit = 4}) async {
    try {
      print('🔍 [CategoryController] getCategoryProducts INICIADO');
      print('📂 [CategoryController] CategoryId: $categoryId');
      print('📊 [CategoryController] Limit: $limit');

      // Obtner 4 productos limitados por cada subCategoria
      final products = await ProductRepository.instance.getProductsForCategory(categoryId: categoryId, limit: limit);

      print('✅ [CategoryController] Productos encontrados: ${products.length}');
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        print('  📦 Producto ${i + 1}: ${p.title} (CategoryId: ${p.categoryId})');
      }

      return products;
    } catch (e) {
      print('❌ [CategoryController] ERROR: $e');
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }
}