import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';

import '../../../../utils/constants/sizes.dart';

class ImagesController extends GetxController {
  static ImagesController get instance => Get.find();

  /// Variables
  RxString selectedProductImage = ''.obs;

  /// -- Obtener todas las imagenes del producto y las variaciones
  List <String> getAllProductImages(ProductModel product) {
    // Usar Set para agregar solo las imágenes únicas
    Set<String> images = {};

    // Cargar miniatura de la imagen
    images.add(product.thumbnail);

    // Asignar Thumbnail como imagen principal
    selectedProductImage.value = product.thumbnail;

    // Obtner todas las imagenes del modelo de producto si no es null
    if (product.images != null) {
      images.addAll(product.images!);
    }

    // Obtener todas las imagenes de las variaciones de producto si no es null
    if (product.productVariations != null || product.productVariations!.isNotEmpty) {
      images.addAll(product.productVariations!.map((variation) => variation.image));
    }

    return images.toList();
  }

  /// -- Mostrar popup de imagenes
  void showEnlargedImage(String image) {
    Get.to(
      fullscreenDialog: true,
        () => Dialog.fullscreen(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TSizes.defaultSpace * 2, horizontal: TSizes.defaultSpace),
                child: CachedNetworkImage(imageUrl: image),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 150,
                  child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
                ),
              ),
            ],
          ),
        ),
    );
  }
}