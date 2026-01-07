import 'package:flutter/material.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';

/// Widget de vista previa de tarjeta de crédito
/// Muestra una representación visual de la tarjeta mientras el usuario ingresa datos
class CardPreview extends StatelessWidget {
  const CardPreview({
    super.key,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.cardType,
  });

  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String cardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: _getCardGradient(cardType),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// Header: Logo y Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Chip de la tarjeta
                Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                /// Logo del tipo de tarjeta
                _buildCardTypeLogo(cardType),
              ],
            ),

            /// Número de tarjeta
            Text(
              cardNumber.isEmpty ? '•••• •••• •••• ••••' : _formatCardNumber(cardNumber),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            /// Footer: Nombre y fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Nombre del titular
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TITULAR',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cardHolderName.isEmpty ? 'NOMBRE COMPLETO' : cardHolderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),

                /// Fecha de expiración
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'VÁLIDA HASTA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formatear número de tarjeta con espacios
  String _formatCardNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }

    // Rellenar con puntos si es necesario
    final formatted = buffer.toString();
    if (formatted.length < 19) {
      final remaining = 19 - formatted.length;
      return formatted + ('•' * remaining);
    }

    return formatted;
  }

  /// Obtener gradiente según tipo de tarjeta
  LinearGradient _getCardGradient(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E), // Azul oscuro
            Color(0xFF283593),
          ],
        );
      case 'mastercard':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEB001B), // Rojo MasterCard
            Color(0xFFFF5F00), // Naranja MasterCard
          ],
        );
      case 'american express':
      case 'amex':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF006FCF), // Azul AmEx
            Color(0xFF0095DA),
          ],
        );
      case 'discover':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6000), // Naranja Discover
            Color(0xFFFF9500),
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TColors.primary,
            TColors.primary.withValues(alpha: 0.7),
          ],
        );
    }
  }

  /// Construir logo del tipo de tarjeta
  Widget _buildCardTypeLogo(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'visa':
        icon = Icons.payment;
        color = Colors.white;
        break;
      case 'mastercard':
        icon = Icons.credit_card;
        color = Colors.white;
        break;
      case 'american express':
      case 'amex':
        icon = Icons.credit_card;
        color = Colors.white;
        break;
      case 'discover':
        icon = Icons.credit_card;
        color = Colors.white;
        break;
      default:
        icon = Icons.credit_card_outlined;
        color = Colors.white70;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          icon,
          color: color,
          size: 40,
        ),
        if (type.isNotEmpty)
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }
}

