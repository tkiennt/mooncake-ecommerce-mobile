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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? 'Khách hàng',
      phoneNumber: json['phoneNumber']?.toString(),
      role: json['role']?.toString() ?? 'Customer',
      companyName: json['companyName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      emailConfirmed: json['emailConfirmed'] == true,
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
}
