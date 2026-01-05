import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tienda_ropa/data/repositories/user/user_repository.dart';
import 'package:tienda_ropa/features/authentication/screens/login/login.dart';
import 'package:tienda_ropa/features/authentication/screens/onboarding/onboarding.dart';
import 'package:tienda_ropa/navigation_menu.dart';
import 'package:tienda_ropa/utils/exceptions/firebase_exceptions.dart';
import 'package:tienda_ropa/utils/exceptions/format_exceptions.dart';
import 'package:tienda_ropa/utils/local_storage/storage_utility.dart';

import '../../../features/authentication/screens/signup/verify_email.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  /// Obtener Authenticated User Data
  User get authUser => _auth.currentUser!;

  /// Llamada desde main.dart al iniciar la app
  @override
  void onReady() {
    // Eliminar Splash Screen
    FlutterNativeSplash.remove();
    // Mostrar pantalla de inicio
    screenRedirect();
  }


  /// Funcion para mostrar la pantalla de inicio
  void screenRedirect() async {
    final user = _auth.currentUser;

    if(user != null) {
      // Si el usuario esta logueado en
      if(user.emailVerified) {

        // Inicializar Almacenamiento especifico para el usuario
        await TLocalStorage.init(user.uid);

        // Si el email esta verificado, redirigir a la pantalla de navegacion
        Get.offAll(() => const NavigationMenu());
      } else {
        // Si el email no esta verificado, redirigir a la pantalla de verificacion
        Get.offAll(() => VerifyEmailScreen(email: _auth.currentUser?.email));
      }
    } else {
      // Local Storage
      deviceStorage.writeIfNull('IsFirstTime', true);
      // Verificar si es la primera vez que se abre la app
      deviceStorage.read('IsFirstTime') != true
          ? Get.offAll(() => const LoginScreen())   // Redireccionar a la pantalla de login si no es la primera vez
          : Get.offAll(const OnBoardingScreen());   // Redireccionar a la pantalla de onBoarding si es la primera vez
    }

  }

  /* -------------------------------- Email & Password sign-in ------------------------------*/

  /// [EmailAuthentication] - SignIn
  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

  /// [EmailAuthentication] - Registrar
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

  /// [EmailVerification] - Email Verificacion
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

  /// [EmailAuthentication] - Olvide Contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

  /// [ReAuthenticate] - ReAuthenticate User
  Future<void> reAuthenticateWithEmailAndPassword(String email, String password) async {
    try {
      // Crear credencial de autenticacion
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);

      // Re-Autenticar el usuario
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

  /*-------------------------------- Federar identidad y redes sociales sign-in -------------------*/
  /// [GoogleAuthentication] - Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Activar el flujo de autenticacion de Google
      final GoogleSignInAccount userAccount = await GoogleSignIn.instance.authenticate();

      // Obtener los detalles de autenticacion de la solicitud
      final GoogleSignInAuthentication googleAuth = userAccount.authentication;

      // Crear una nueva credencial
      final credentials = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      // Una vez iniciada la sesion, retornar el UserCredential
      return await _auth.signInWithCredential(credentials);

    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (kDebugMode) print('Algo salio mal: $e');
      return null;
    }
  }


  /// [FacebookAuthentication] - Facebook

  /* -------------------------------- Email & Password sign-in ------------------------------*/

  /// [LogoutUser] - Valido para cualquier tipo de autenticacion
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

  /// [DeleteUser] - Eliminar usuario Auth y FireStore Account
  Future<void> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Intentelo de nuevo.';
    }
  }

}