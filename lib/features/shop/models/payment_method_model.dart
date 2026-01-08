import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';

class PaymentMethodModel {
  String id;
  String? cardHolderName;
  String? cardNumberLast4; // Solo almacenamos los últimos 4 dígitos
  String? cardType; // Visa, MasterCard, AmEx, Discover
  String? expiryDate; // Formato: MM/YY
  bool isDefault;
  DateTime? createdAt;

  // Campos heredados del modelo anterior (para retrocompatibilidad)
  String name;
  String image;

  PaymentMethodModel({
    this.id = '',
    this.cardHolderName,
    this.cardNumberLast4,
    this.cardType,
    this.expiryDate,
    this.isDefault = false,
    this.createdAt,
    this.name = '',
    this.image = '',
  });

  /// Método vacío para inicialización
  static PaymentMethodModel empty() => PaymentMethodModel(
        id: '',
        cardHolderName: '',
        cardNumberLast4: '',
        cardType: '',
        expiryDate: '',
        isDefault: false,
        name: '',
        image: '',
      );

  /// Obtener número de tarjeta enmascarado para mostrar en UI
  String get maskedCardNumber => '**** **** **** ${cardNumberLast4 ?? '****'}';

  /// Obtener la imagen del tipo de tarjeta basado en cardType
  String get cardTypeImage {
    // Si tiene image antigua, usarla
    if (image.isNotEmpty) return image;

    // Sino, usar cardType para determinar la imagen
    switch (cardType?.toLowerCase() ?? '') {
      case 'visa':
        return TImages.visa;
      case 'mastercard':
        return TImages.masterCard;
      case 'amex':
      case 'american express':
        return TImages.applepay; // Usando apple pay como placeholder para AmEx si no hay icono específico
      case 'discover':
        return TImages.creditCard; // Usando creditCard como placeholder para Discover
      default:
        return TImages.creditCard;
    }
  }

  /// Obtener el nombre a mostrar (compatibilidad name o cardHolderName)
  String get displayName => name.isNotEmpty ? name : (cardHolderName ?? '');

  /// Detectar tipo de tarjeta basado en el número
  static String detectCardType(String cardNumber) {
    // Eliminar espacios y guiones
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanNumber.isEmpty) return '';

    // Visa: empieza con 4
    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    }

    // MasterCard: empieza con 51-55 o 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(cleanNumber) ||
        RegExp(r'^2(22[1-9]|2[3-9][0-9]|[3-6][0-9][0-9]|7[0-1][0-9]|720)')
            .hasMatch(cleanNumber)) {
      return 'MasterCard';
    }

    // American Express: empieza con 34 o 37
    if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return 'American Express';
    }

    // Discover: empieza con 6011, 622126-622925, 644-649, o 65
    if (cleanNumber.startsWith('6011') ||
        RegExp(r'^62212[6-9]|^6229[01][0-9]|^622[2-8][0-9]{2}')
            .hasMatch(cleanNumber) ||
        RegExp(r'^64[4-9]').hasMatch(cleanNumber) ||
        cleanNumber.startsWith('65')) {
      return 'Discover';
    }

    return 'Unknown';
  }

  /// Obtener últimos 4 dígitos de un número de tarjeta
  static String getLast4Digits(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (cleanNumber.length >= 4) {
      return cleanNumber.substring(cleanNumber.length - 4);
    }
    return cleanNumber;
  }

  /// Formatear número de tarjeta con espacios (para mostrar mientras escribe)
  static String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }

    return buffer.toString();
  }

  /// Convertir modelo a JSON para Firebase
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'CardHolderName': cardHolderName,
      'CardNumberLast4': cardNumberLast4,
      'CardType': cardType,
      'ExpiryDate': expiryDate,
      'IsDefault': isDefault,
      'CreatedAt': createdAt ?? DateTime.now(),
      // Mantener compatibilidad
      'Name': name,
      'Image': image,
    };
  }

  /// Crear modelo desde JSON de Firebase
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['Id'] ?? '',
      cardHolderName: json['CardHolderName'],
      cardNumberLast4: json['CardNumberLast4'],
      cardType: json['CardType'],
      expiryDate: json['ExpiryDate'],
      isDefault: json['IsDefault'] ?? false,
      createdAt: json['CreatedAt'] != null
          ? (json['CreatedAt'] as Timestamp).toDate()
          : null,
      name: json['Name'] ?? '',
      image: json['Image'] ?? '',
    );
  }

  /// Crear modelo desde DocumentSnapshot de Firebase
  factory PaymentMethodModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return PaymentMethodModel(
      id: snapshot.id,
      cardHolderName: data['CardHolderName'],
      cardNumberLast4: data['CardNumberLast4'],
      cardType: data['CardType'],
      expiryDate: data['ExpiryDate'],
      isDefault: data['IsDefault'] ?? false,
      createdAt: data['CreatedAt'] != null
          ? (data['CreatedAt'] as Timestamp).toDate()
          : null,
      name: data['Name'] ?? '',
      image: data['Image'] ?? '',
    );
  }

  /// Copiar modelo con cambios (útil para edición)
  PaymentMethodModel copyWith({
    String? id,
    String? cardHolderName,
    String? cardNumberLast4,
    String? cardType,
    String? expiryDate,
    bool? isDefault,
    DateTime? createdAt,
    String? name,
    String? image,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumberLast4: cardNumberLast4 ?? this.cardNumberLast4,
      cardType: cardType ?? this.cardType,
      expiryDate: expiryDate ?? this.expiryDate,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      image: image ?? this.image,
    );
  }
}