/// Custom exception class to handle various format-related errors.
class TFormatException implements Exception {
  /// The associated error message.
  final String message;

  /// Default constructor with a generic error message.
  const TFormatException([this.message = 'Un error en el formato ha ocurrido. Por favor verifica tu entrada.']);

  /// Create a format exception from a specific error message.
  factory TFormatException.fromMessage(String message) {
    return TFormatException(message);
  }

  /// Get the corresponding error message.
  String get formattedMessage => message;

  /// Create a format exception from a specific error code.
  factory TFormatException.fromCode(String code) {
    switch (code) {
      case 'invalid-email-format':
        return const TFormatException('El format de email es invalido. Por favor ingrese un email valido.');
      case 'invalid-phone-number-format':
        return const TFormatException('El numero de telefono es invalido. Por favor ingrese un numero de telefono valido.');
      case 'invalid-date-format':
        return const TFormatException('El formato de fecha es invalido. Por favor ingrese una fecha valida.');
      case 'invalid-url-format':
        return const TFormatException('La formato de URL es invalido. Por favor ingrese una URL valida.');
      case 'invalid-credit-card-format':
        return const TFormatException('La tarjeta de credito es invalida. Por favor ingrese una tarjeta de credito valida.');
      case 'invalid-numeric-format':
        return const TFormatException('La entrada no es un numero valido. Por favor ingrese un numero valido.');
    // Add more cases as needed...
      default:
        return const TFormatException();
    }
  }
}