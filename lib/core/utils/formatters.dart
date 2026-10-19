const _bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
const _bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String bulanPendek(DateTime d) => _bulanPendek[d.month - 1];

/// "Sabtu, 17 Oktober 2026"
String tanggalLengkap(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// "27 Agu 2026"
String tanggalPendek(DateTime? d) => d == null ? '—' : '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';

String _two(int n) => n.toString().padLeft(2, '0');

/// "17 Okt 2026, 07:28:35"
String waktuLengkap(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_bulanPendek[l.month - 1]} ${l.year}, ${_two(l.hour)}:${_two(l.minute)}:${_two(l.second)}';
}

/// "kurang dari 1 menit yang lalu", "sekitar 2 jam yang lalu", ...
String waktuRelatif(DateTime? d) {
  if (d == null) return '—';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'kurang dari 1 menit yang lalu';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
  if (diff.inHours < 24) return 'sekitar ${diff.inHours} jam yang lalu';
  if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
  return tanggalPendek(d);
}

String inisial(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// "07:28"
String jamMenit(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// "16 September 2026"
String tanggalLengkapTanpaHari(DateTime? d) => d == null ? '—' : '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// "Kamis, 1 Okt"
String hariTanggalPendek(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulanPendek[d.month - 1]}';
