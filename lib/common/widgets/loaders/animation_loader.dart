import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// Widget para desplegar el indicador animado de carga con un texto y boton de accion opcional
class TAnimationLoaderWidget extends StatelessWidget {
  /// Constructor por defecto para TAnimationLoaderWidget.
  ///
  /// Parametros:
  ///   - text: El texto a mostrar junto a la animacion
  ///   - animation: La animacion Lottie a mostrar
  ///   - showAction: Un boton junto al texto para mostrar la accion
  ///   - actionText: El texto del boton de accion
  ///   - onActionPressed: La funcion a ejecutar cuando se toca el boton de accion
  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    required this.animation,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
  });

  final String text;
  final String animation;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(animation, width: MediaQuery.of(context).size.width * 0.8),
          const SizedBox(height: TSizes.defaultSpace),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.defaultSpace),
          showAction
              ? SizedBox(
            width: 250,
            child: OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(backgroundColor: TColors.dark),
              child: Text(
                actionText!,
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.light),
              ),
            ),
          )
              : const SizedBox(),
        ],
      ),
    );
  }
}