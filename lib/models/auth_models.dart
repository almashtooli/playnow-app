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
  final String? phone;
  final String? birthDate;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.birthDate,
  });

  Map<String, dynamic> toJson() => {
    'fullName': name,
    'email': email,
    'password': password,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (birthDate != null) 'birthDate': birthDate,
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
  final String? avatarUrl;
  final List<String> roles;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.roles,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id:        json['id'] ?? 0,
      name:      json['fullName'] ?? json['name'] ?? '',
      email:     json['email'] ?? '',
      phone:     json['phone'],
      avatarUrl: json['avatarUrl'],
      roles:     List<String>.from(json['roles'] ?? []),
    );
  }

  AuthUser copyWith({String? name, String? phone, String? avatarUrl}) {
    return AuthUser(
      id:        id,
      name:      name ?? this.name,
      email:     email,
      phone:     phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roles:     roles,
    );
  }

  bool get isVenue => roles.contains('venue');
  bool get isAdmin => roles.contains('admin');
  bool get isPlayer => roles.contains('player');
}
