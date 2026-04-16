class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phoneNum;
  final String? gender;
  final String? username;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNum,
    this.username,
    this.gender,
    this.photoUrl,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'],
      email: map['email'],
      phoneNum: map['phoneNum'],
      gender: map['gender'],
      username: map['username'],
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNum': phoneNum,
      'gender': gender,
      'username': username,
      'photoUrl': photoUrl,
    };
  }
}
