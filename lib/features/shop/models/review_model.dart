import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  String id;
  String productId;
  String userId;
  String userName;
  String userProfileImage;
  double rating;
  String comment;
  DateTime createdAt;
  DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  /// Crear una instancia vacía para un código limpio
  static ReviewModel empty() => ReviewModel(
        id: '',
        productId: '',
        userId: '',
        userName: '',
        userProfileImage: '',
        rating: 0.0,
        comment: '',
        createdAt: DateTime.now(),
      );

  /// Convertir el modelo a una estructura de datos Json para Firebase
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'ProductId': productId,
      'UserId': userId,
      'UserName': userName,
      'UserProfileImage': userProfileImage,
      'Rating': rating,
      'Comment': comment,
      'CreatedAt': Timestamp.fromDate(createdAt),
      'UpdatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Mapeado Json orientado al documento de Firebase al ReviewModel
  factory ReviewModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) return ReviewModel.empty();
    return ReviewModel(
      id: data['Id'] ?? '',
      productId: data['ProductId'] ?? '',
      userId: data['UserId'] ?? '',
      userName: data['UserName'] ?? '',
      userProfileImage: data['UserProfileImage'] ?? '',
      rating: (data['Rating'] ?? 0.0).toDouble(),
      comment: data['Comment'] ?? '',
      createdAt: (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Mapeado desde DocumentSnapshot de Firebase al ReviewModel
  factory ReviewModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      return ReviewModel(
        id: document.id,
        productId: data['ProductId'] ?? '',
        userId: data['UserId'] ?? '',
        userName: data['UserName'] ?? '',
        userProfileImage: data['UserProfileImage'] ?? '',
        rating: (data['Rating'] ?? 0.0).toDouble(),
        comment: data['Comment'] ?? '',
        createdAt:
            (data['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['UpdatedAt'] as Timestamp?)?.toDate(),
      );
    } else {
      return ReviewModel.empty();
    }
  }

  /// Método para crear una copia del modelo con valores actualizados
  ReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userProfileImage,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Método toString para debugging
  @override
  String toString() {
    return 'ReviewModel{id: $id, productId: $productId, userId: $userId, userName: $userName, rating: $rating, comment: $comment, createdAt: $createdAt}';
  }
}

