class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'fullName': name, // backend column is full_name → expects fullName
    'email': email,
    'password': password,
  };
}

class PhoneLoginRequest {
  final String firebaseToken;

  PhoneLoginRequest({required this.firebaseToken});

  Map<String, dynamic> toJson() => {'firebaseToken': firebaseToken};
}

class UpdateProfileRequest {
  final String? fullName;
  final String? phone;

  UpdateProfileRequest({this.fullName, this.phone});

  Map<String, dynamic> toJson() => {
    if (fullName != null) 'fullName': fullName,
    if (phone != null) 'phone': phone,
  };
}

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? 0,
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  AuthUser copyWith({String? name, String? phone}) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      roles: roles,
    );
  }

  bool get isVenue => roles.contains('venue');
  bool get isAdmin => roles.contains('admin');
  bool get isPlayer => roles.contains('player');
}
