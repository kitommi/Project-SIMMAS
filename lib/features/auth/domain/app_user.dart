enum UserRole {
  admin,
  guru,
  siswa;

  static UserRole? tryParse(String? value) {
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }

  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.guru => 'Guru Pembimbing',
        UserRole.siswa => 'Siswa',
      };

  /// Rute beranda dashboard sesuai role (sama dengan situs asli).
  String get homePath => '/$name/dashboard';
}

class AppUser {
  const AppUser({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String nama;
  final String email;
  final UserRole role;
  final String? avatarUrl;

  String get initial => nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        nama: (map['nama'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        role: UserRole.tryParse(map['role'] as String?) ?? UserRole.siswa,
        avatarUrl: map['avatar_url'] as String?,
      );
}
