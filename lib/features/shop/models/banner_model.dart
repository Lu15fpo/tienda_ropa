import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  String imageUrl;
  final String targetScreen;
  final bool active;

  BannerModel({required this.imageUrl, required this.targetScreen, required this.active});

  Map<String, dynamic> toJson() {
    return {
      'ImageURL': imageUrl,
      'TargetScreen': targetScreen,
      'Active': active,
    };
  }

  factory BannerModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return BannerModel(
      imageUrl: data['ImageURL'] ?? '',
      targetScreen: data['TargetScreen'] ?? '',
      active: data['Active'] ?? false,
    );
  }
}