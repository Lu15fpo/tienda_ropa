import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';

import '../../../../../utils/constants/sizes.dart';

class TRatingAndShare extends StatelessWidget {
  const TRatingAndShare({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Calificacion
        Row(
          children: [
            Icon(Iconsax.star5, color: Colors.amber, size: 24),
            SizedBox(width: TSizes.spaceBtwItems / 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '5.0', style: Theme.of(context).textTheme.bodyLarge),
                  const TextSpan(text: '(199)')
                ],
              ),
            ),
          ],
        ),
        /// Boton de compartir
        IconButton(
          onPressed: () {
            // Compartir información del producto
            final String shareText = '''
¡Mira este producto increíble! 🛍️

${product.title}
${product.brand != null ? 'Marca: ${product.brand!.name}' : ''}
Precio: \$${product.salePrice > 0 ? product.salePrice : product.price}

${product.description ?? 'Sin descripción disponible'}

🔗 [En desarrollo - URL del producto estará disponible próximamente]
ID del Producto: ${product.id}
''';
            SharePlus.instance.share(
              ShareParams(text: shareText, subject: product.title)
            );
          },
          icon: const Icon(Icons.share, size: TSizes.iconMd)
        ),
      ],
    );
  }
}
