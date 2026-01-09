import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/formatters/formatter.dart';

class UserModel {
  // Mantener estos valores finales cuando no se quiera modificar.
  final String id;
  final String username;
  final String email;
  String firstName;
  String lastName;
  String phoneNumber;
  String profilePicture;
  String cedula; // Cédula o RUC para facturación electrónica

  /// Constructor para UserModel
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.profilePicture,
    this.cedula = '', // Opcional, puede estar vacío inicialmente
  });

  /// Funcion de ayuda para obtener el nombre completo del usuario
  String get fullName => '$firstName $lastName';

  /// Funcion de ayuda para el formato de numero de telefono
  String get formattedPhoneNumber => TFormatter.formatPhoneNumber(phoneNumber);

  /// Funcion estatica para obtener partes del nombre
  static List<String> nameParts(String fullName) => fullName.split(" ");

  /// Funcion estatica para generar un nombre de usuario a partir del nombre completo
  static String generateUsername(String fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : "";

    String camelCaseUsername = "$firstName$lastName"; // Combina el primer y segundo nombre en camelCase
    String usernameWithPrefix = "MLC_$camelCaseUsername"; // Agregar "MLC_" como prefijo de usuario
    return usernameWithPrefix;
  }

  /// Funcion estatica para crear un modelo de usuario vacio
  static UserModel empty() => UserModel(
      id: '',
      firstName: '',
      lastName: '',
      username: '',
      email: '',
      phoneNumber: '',
      profilePicture: '',
      cedula: '');

  /// Convertir el modelo a una estructura de datos JSON para almacenar en los datos de FIrebase.
  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'Username': username,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'ProfilePicture': profilePicture,
      'Cedula': cedula,
    };
  }

  /// Metodo Factory para crear un modelo de usuario para el documento de Firebase.
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return UserModel(
      id: document.id,
      firstName: data['FirstName'] ?? '',
      lastName: data['LastName'] ?? '',
      username: data['Username'] ?? '',
      email: data['Email'] ?? '',
      phoneNumber: data['PhoneNumber'] ?? '',
      profilePicture: data['ProfilePicture'] ?? '',
      cedula: data['Cedula'] ?? '',
    );
  }
}