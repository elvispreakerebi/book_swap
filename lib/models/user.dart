import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool emailVerified;
  final Timestamp createdAt;
  final bool notificationEnabled;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.emailVerified,
    required this.createdAt,
    required this.notificationEnabled,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt,
      'notificationEnabled': notificationEnabled,
    };
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? emailVerified,
    Timestamp? createdAt,
    bool? notificationEnabled,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
