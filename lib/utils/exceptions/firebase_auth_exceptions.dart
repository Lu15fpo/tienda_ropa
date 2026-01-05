/// Custom exception class to handle various Firebase authentication-related errors.
class TFirebaseAuthException implements Exception {
  /// The error code associated with the exception.
  final String code;

  /// Constructor that takes an error code.
  TFirebaseAuthException(this.code);

  /// Get the corresponding error message based on the error code.
  String get message {
    switch (code) {
      case 'email-already-in-use':
        return 'El email ya está en uso. Por favor, utiliza otra direccion de email.';
      case 'invalid-email':
        return 'La direccion de email proporcionada es invalida. Por favor ingresa una direccion de email valida.';
      case 'weak-password':
        return 'La contraseña es muy débil. Por favor ingresa una contraseña más segura.';
      case 'user-disabled':
        return 'Esta cuenta de usuario ha sido deshabilitada. Por favor contacte con soporte para más información.';
      case 'user-not-found':
        return 'Login invalido. No se encontró el usuario.';
      case 'wrong-password':
        return 'Constraseña incorrecta.Por favor intente de nuevo.';
      case 'invalid-verification-code':
        return 'Codigo de verificacion incorrecto. Por favor ingrese un codigo valido.';
      case 'invalid-verification-id':
        return 'Verificacion de ID invalida. Por favor solicite un nuevo codigo de verificacion.';
      case 'quota-exceeded':
        return 'Cupo excedido. Intente de nuevo mas tarde.';
      case 'email-already-exists':
        return 'La direccion de email ya existe. Por favor ingresa otra direccion de email.';
      case 'provider-already-linked':
        return 'La cuenta ya está vinculada con otro proveedor.';
      case 'requires-recent-login':
        return 'Esta operacion es sensible y requiere autentificacion de inicio de sesion mas reciente. Por favor inicie sesion nuevamente.';
      case 'credential-already-in-use':
        return 'Estas credenciales ya estan en uso por otro usuario.';
      case 'user-mismatch':
        return 'Las credenciales proporcionadas no coinciden con el usuario actual.';
      case 'account-exists-with-different-credential':
        return 'Una cuenta ya existe con el mismo email pero con credenciales diferentes.';
      case 'operation-not-allowed':
        return 'Esta operacion no esta permitida. Por favor contacte con soporte para más información.';
      case 'expired-action-code':
        return 'El codigo ha expirado. Por favor solicite un nuevo codigo.';
      case 'invalid-action-code':
        return 'El codigo es invalido. Por favor verifica el codigo y vuelve a intentarlo.';
      case 'missing-action-code':
        return 'El codigo no se envio. Por favor solicite un nuevo codigo e intente de nuevo.';
      case 'user-token-expired':
        return 'El token de usuario ha expirado. Por favor inicie sesion nuevamente.';
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son invalidas o ha expirado.';
      case 'user-token-revoked':
        return 'El token de usuario ha sido revocado. Por favor inicie sesion nuevamente.';
      case 'invalid-message-payload':
        return 'El correo electronico no contiene un payload valido.';
      case 'invalid-sender':
        return 'El remitente del correo electronico es invalido. Por favor verifica el remitente y vuelve a intentarlo.';
      case 'invalid-recipient-email':
        return 'El destinatario del correo electronico es invalido. Por favor verifica el destinatario y vuelve a intentarlo.';
      case 'missing-iframe-start':
        return 'El email se encuentra incompleto. Por favor agrega el iframe de inicio.';
      case 'missing-iframe-end':
        return 'El email se encuentra incompleto. Por favor agrega el iframe de finalizacion.';
      case 'missing-iframe-src':
        return 'El email esta incompleto. Por favor agrega el atributo src en el iframe.';
      case 'auth-domain-config-required':
        return 'El authDomain configuracion es requerida para la accion de verificacion del codigo.';
      case 'missing-app-credential':
        return 'Las credenciales de la aplicacion son requeridas. Por favor proporciona las credenciales de la aplicacion.';
      case 'invalid-app-credential':
        return 'Las credenciales de la aplicacion son invalidas. Por favor proporciona credenciales validas.';
      case 'session-cookie-expired':
        return 'La sesion de Firebase a expirado. Por favor vuelve a intentarlo';
      case 'uid-already-exists':
        return 'El ID de usuario ya esta en uso por otro usuario.';
      case 'invalid-cordova-configuration':
        return 'El archivo cordova.js no se encuentra en el directorio correcto.';
      case 'app-deleted':
        return 'Esta instancia de FirebaseApp ha sido eliminada.';
      case 'user-token-mismatch':
        return 'El token de usuario proporcionado no coincide con el ID de usuario actual.';
      case 'web-storage-unsupported':
        return 'El almacenamiento web no es soportado o esta deshabilitado.';
      case 'app-not-authorized':
        return 'La app no esta autorizada para usar Firebase Authentication con la clave proporcionada.';
      case 'keychain-error':
        return 'Ocurrio un error al acceder a la keychain. Por favor verifica las credenciales y vuelve a intentarlo.';
      case 'internal-error':
        return 'Un error interno ocurrio. Por favor intenta de nuevo mas tarde.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Credenciales de acceso invalidas.';
      default:
        return 'Ocurrio un error inesperado al autenticar. Por favor intenta de nuevo.';
    }
  }
}
