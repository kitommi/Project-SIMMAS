String _s(dynamic v, [String d = '']) => v?.toString() ?? d;
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
Map<String, dynamic> _m(dynamic v) => (v as Map?)?.cast<String, dynamic>() ?? const {};

class BimbinganRow {
  const BimbinganRow({
    required this.id,
    required this.siswa,
    required this.nis,
    required this.kelas,
    required this.dudi,
    required this.status,
    required this.mulai,
    required this.selesai,
  });

  final String id, siswa, nis, kelas, dudi, status;
  final DateTime? mulai, selesai;

  factory BimbinganRow.fromMap(Map<String, dynamic> m) => BimbinganRow(
        id: _s(m['id']),
        siswa: _s(m['siswa']),
        nis: _s(m['nis']),
        kelas: _s(m['kelas'], '—'),
        dudi: _s(m['dudi'], '—'),
        status: _s(m['status'], 'aktif'),
        mulai: _dt(m['tanggal_mulai']),
        selesai: _dt(m['tanggal_selesai']),
      );
}

class JurnalItem {
  const JurnalItem({
    required this.id,
    required this.tanggal,
    required this.siswa,
    required this.nis,
    required this.kegiatan,
    required this.kendala,
    required this.status,
    required this.catatan,
    required this.foto,
  });

  final String id, siswa, nis, kegiatan, kendala, status, catatan;
  final String? foto;
  final DateTime? tanggal;

  factory JurnalItem.fromMap(Map<String, dynamic> m) {
    final siswa = _m(_m(m['penempatan'])['siswa']);
    return JurnalItem(
      id: _s(m['id']),
      tanggal: _dt(m['tanggal']),
      siswa: _s(siswa['nama'], '-'),
      nis: _s(siswa['nis']),
      kegiatan: _s(m['kegiatan']),
      kendala: _s(m['kendala']),
      status: _s(m['status'], 'menunggu'),
      catatan: _s(m['catatan_guru']),
      foto: m['foto_path'] as String?,
    );
  }
}

class AbsensiItem {
  const AbsensiItem({
    required this.id,
    required this.tanggal,
    required this.siswa,
    required this.nis,
    required this.jamMasuk,
    required this.jamKeluar,
    required this.status,
    required this.keterangan,
  });

  final String id, siswa, nis, status, keterangan;
  final DateTime? tanggal, jamMasuk, jamKeluar;

  factory AbsensiItem.fromMap(Map<String, dynamic> m) {
    final siswa = _m(_m(m['penempatan'])['siswa']);
    return AbsensiItem(
      id: _s(m['id']),
      tanggal: _dt(m['tanggal']),
      siswa: _s(siswa['nama'], '-'),
      nis: _s(siswa['nis']),
      jamMasuk: _dt(m['jam_masuk']),
      jamKeluar: _dt(m['jam_keluar']),
      status: _s(m['status'], 'hadir'),
      keterangan: _s(m['keterangan'], '—'),
    );
  }
}

class KunjunganItem {
  const KunjunganItem({required this.id, required this.dudi, required this.tanggal, required this.catatan});

  final String id, dudi, catatan;
  final DateTime? tanggal;

  factory KunjunganItem.fromMap(Map<String, dynamic> m) => KunjunganItem(
        id: _s(m['id']),
        dudi: _s(_m(m['dudi'])['nama'], '-'),
        tanggal: _dt(m['tanggal']),
        catatan: _s(m['catatan']),
      );
}
