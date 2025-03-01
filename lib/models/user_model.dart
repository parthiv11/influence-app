import 'dart:convert';

class UserModel {
  final String uid;
  final Map<String, dynamic> data;

  // Constructor with required uid and optional data map
  UserModel({required this.uid, Map<String, dynamic>? data})
    : this.data = data ?? {};

  // Getters for common fields with null safety
  String get name => data['name'] as String? ?? '';
  String get email => data['email'] as String? ?? '';
  String get profilePic => data['profilePic'] as String? ?? '';
  String get bio => data['bio'] as String? ?? '';
  String get website => data['website'] as String? ?? '';
  String? get userType => data['userType'] as String?;
  Map<String, dynamic>? get metrics => data['metrics'] as Map<String, dynamic>?;
  Map<String, dynamic>? get socialAccounts =>
      data['socialAccounts'] as Map<String, dynamic>?;

  // Setters for common fields
  set name(String value) => data['name'] = value;
  set email(String value) => data['email'] = value;
  set profilePic(String value) => data['profilePic'] = value;
  set bio(String value) => data['bio'] = value;
  set website(String value) => data['website'] = value;

  // General getter/setter for any field
  dynamic operator [](String key) => data[key];
  operator []=(String key, dynamic value) => data[key] = value;

  // Create a copy with updated values
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? profilePic,
    String? bio,
    String? website,
    String? userType,
    Map<String, dynamic>? metrics,
    Map<String, dynamic>? socialAccounts,
  }) {
    final newData = Map<String, dynamic>.from(data);

    if (name != null) newData['name'] = name;
    if (email != null) newData['email'] = email;
    if (profilePic != null) newData['profilePic'] = profilePic;
    if (bio != null) newData['bio'] = bio;
    if (website != null) newData['website'] = website;
    if (userType != null) newData['userType'] = userType;
    if (metrics != null) newData['metrics'] = metrics;
    if (socialAccounts != null) newData['socialAccounts'] = socialAccounts;

    return UserModel(uid: uid ?? this.uid, data: newData);
  }

  // Convert to a Map
  Map<String, dynamic> toMap() {
    return {'uid': uid, ...data};
  }

  // Create from a Map
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final data = Map<String, dynamic>.from(map);
    // Remove uid from data map to avoid duplication
    data.remove('uid');

    return UserModel(uid: documentId, data: data);
  }

  // JSON serialization
  String toJson() => json.encode(toMap());
  factory UserModel.fromJson(String source, String documentId) =>
      UserModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
        documentId,
      );

  @override
  String toString() => 'UserModel(uid: $uid, data: $data)';

  // Check if a field exists
  bool hasField(String field) => data.containsKey(field);
}
