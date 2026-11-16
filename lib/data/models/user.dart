class User {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? role;
  final String? companyName;
  final String? avatarUrl;
  final bool emailConfirmed;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.role,
    this.companyName,
    this.avatarUrl,
    this.emailConfirmed = true,
  });

  String? get phone => phoneNumber;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? 'Khách hàng',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString(),
      role: json['role']?.toString() ?? 'Customer',
      companyName: json['companyName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      emailConfirmed: json['emailConfirmed'] == true || json['emailConfirmed'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'role': role,
    'companyName': companyName,
    'avatarUrl': avatarUrl,
    'emailConfirmed': emailConfirmed,
  };

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? role,
    String? companyName,
    String? avatarUrl,
    bool? emailConfirmed,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailConfirmed: emailConfirmed ?? this.emailConfirmed,
    );
  }
}
