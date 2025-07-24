class UserModel {
  final String uid;
  final String email;
  final String username;

  UserModel({required this.uid, required this.email, required this.username});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'username': username};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
    );
  }
}
