/// Exception class for handling various errors.
class TExceptions implements Exception {
  /// The associated error message.
  final String message;

  /// Default constructor with a generic error message.
  const TExceptions([this.message = 'An unexpected error occurred. Please try again.']);

  /// Create an authentication exception from a Firebase authentication exception code.
  factory TExceptions.fromCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const TExceptions('El email ya está en uso. Por favor, utiliza otro email.');
      case 'invalid-email':
        return const TExceptions('El email es inavlido. Por favor ingrese un email valido.');
      case 'weak-password':
        return const TExceptions('La constraseña es muy débil. Por favor ingrese una contraseña más segura.');
      case 'user-disabled':
        return const TExceptions('Esta cuenta de usuario ha sido deshabilitada. Por favor contacte con soporte para más información.');
      case 'user-not-found':
        return const TExceptions('Login invalido. No se encontró el usuario.');
      case 'wrong-password':
        return const TExceptions('Constraseña incorrecta.Por favor intente de nuevo.');
      case 'INVALID_LOGIN_CREDENTIALS':
        return const TExceptions('Crendeciales de acceso invalidas. Por favor verifique su información.');
      case 'too-many-requests':
        return const TExceptions('Demasiados intentos. Por favor intente de nuevo más tarde.');
      case 'invalid-argument':
        return const TExceptions('Argumento invalido para el método de autenticación.');
      case 'invalid-password':
        return const TExceptions('Contraseña invalida. Por favor intente de nuevo.');
      case 'invalid-phone-number':
        return const TExceptions('El numero de telefono es invalido. Por favor ingrese un numero de telefono valido.');
      case 'operation-not-allowed':
        return const TExceptions('El proveedor de inicio de sesion esta desactivado para tu proyecto de Firebase.');
      case 'session-cookie-expired':
        return const TExceptions('La sesion de Firebase a expirado. Por favor vuelve a intentarlo');
      case 'uid-already-exists':
        return const TExceptions('El ID de usuario ya esta en uso por otro usuario.');
      case 'sign_in_failed':
        return const TExceptions('Inicio de Sesion fallido. Por favor intente de nuevo.');
      case 'network-request-failed':
        return const TExceptions('Solicitud de conexion fallida. Por favor verifique su conexion a internet.');
      case 'internal-error':
        return const TExceptions('Error interno. Por favor intente de nuevo más tarde.');
      case 'invalid-verification-code':
        return const TExceptions('Codigo de verificacion incorrecto. Por favor ingrese un codigo valido.');
      case 'invalid-verification-id':
        return const TExceptions('Verificacion de ID invalida. Por favor solicite un nuevo codigo de verificacion.');
      case 'quota-exceeded':
        return const TExceptions('Cupo excedido. Intente de nuevo mas tarde.');
      default:
        return const TExceptions();
    }
  }
}
