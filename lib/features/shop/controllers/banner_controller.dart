import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/banner_model.dart';

import '../../../data/repositories/banners/banner_repository.dart';
import '../../../utils/popups/loaders.dart';

class BannerController extends GetxController {

  /// Variables
  final isLoading = false.obs;
  final carousalCurrentIndex = 0.obs;
  final RxList<BannerModel> banners = <BannerModel>[].obs;


  @override
  void onInit() {
    fetchBanners();
    super.onInit();
  }

  /// Actualizar Barras de navegacion en la pagina
  void updatePageIndicator(int index) {
    carousalCurrentIndex.value = index;
  }

  /// Obtener Banners
  Future<void> fetchBanners() async {
    try {
      // Mostrar la carga de las categorias cargadas
      isLoading.value = true;

      // Obtener Banners
      final bannerRepo = Get.put(BannerRepository());
      final banners = await bannerRepo.fetchBanners();

      // Asignar Banners
      this.banners.assignAll(banners);


    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    } finally {
      // Eliminar la Carga
      isLoading.value = false;
    }

  }
}