class UserProfile {
  final String id;
  final String name;
  final String nameLower;
  final String email;
  final String? phoneNum;
  final String? gender;
  final String? username;
  final String? usernameLower;
  final String? imgUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNum,
    this.username,
    this.gender,
    this.imgUrl,
    required this.nameLower,
    this.usernameLower,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'],
      nameLower: map['nameLower'],
      email: map['email'],
      phoneNum: map['phoneNum'],
      gender: map['gender'],
      username: map['username'],
      usernameLower: map['usernameLower'],
      imgUrl: map['imgUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameLower': nameLower,
      'email': email,
      'phoneNum': phoneNum,
      'gender': gender,
      'username': username,
      'usernameLower': usernameLower,
      'photoUrl': imgUrl,
    };
  }
}
