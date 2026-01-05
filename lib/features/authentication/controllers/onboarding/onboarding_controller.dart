import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tienda_ropa/features/authentication/screens/login/login.dart';

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  /// Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  /// Actualizar pagina Index cuando se hace scroll
  void updatePageIndicator(int index) => currentPageIndex.value = index;

  /// Saltar a la pagina seleccionada especificada
  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  /// Actualizar el Index y saltar a la siguiente pagina
  void nextPage() {
    if(currentPageIndex.value == 2) {
      final storage = GetStorage();

      if (kDebugMode) {
        print('===================GET STORAGE Next Button====================');
        print(storage.read('IsFirstTime'));
      }

      storage.write('IsFirstTime', false);

      if (kDebugMode) {
        print('===================GET STORAGE Next Button====================');
        print(storage.read('IsFirstTime'));
      }

      Get.offAll(const LoginScreen());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  /// Actualizar el Index y saltar a la pagina anterior
  void skipPage() {
    currentPageIndex.value = 2;
    pageController.jumpToPage(2);
  }
}