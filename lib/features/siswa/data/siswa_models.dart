String _s(dynamic v, [String d = '']) => v?.toString() ?? d;
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
Map<String, dynamic> _m(dynamic v) => (v as Map?)?.cast<String, dynamic>() ?? const {};

String _lokasi(Map<String, dynamic> dudi) {
  final parts = [_s(dudi['alamat']), _s(dudi['kota'])].where((e) => e.isNotEmpty).toList();
  return parts.isEmpty ? '—' : parts.join(', ');
}

class Penempatan {
  const Penempatan({
    required this.id,
    required this.dudi,
    required this.lokasi,
    required this.pembimbing,
    required this.mulai,
    required this.selesai,
  });

  final String id, dudi, lokasi;
  final String? pembimbing;
  final DateTime? mulai, selesai;

  bool get hasPembimbing => pembimbing != null && pembimbing!.isNotEmpty;

  factory Penempatan.fromMap(Map<String, dynamic> m) {
    final dudi = _m(m['dudi']);
    return Penempatan(
      id: _s(m['id']),
      dudi: _s(dudi['nama'], '-'),
      lokasi: _lokasi(dudi),
      pembimbing: _m(m['guru'])['nama'] as String?,
      mulai: _dt(m['tanggal_mulai']),
      selesai: _dt(m['tanggal_selesai']),
    );
  }
}

class PengajuanSiswa {
  const PengajuanSiswa({
    required this.id,
    required this.status,
    required this.posisi,
    required this.catatan,
    required this.diajukan,
    required this.dudi,
    required this.lokasi,
  });

  final String id, status, posisi, catatan, dudi, lokasi;
  final DateTime? diajukan;

  factory PengajuanSiswa.fromMap(Map<String, dynamic> m) {
    final dudi = _m(m['dudi']);
    return PengajuanSiswa(
      id: _s(m['id']),
      status: _s(m['status'], 'menunggu'),
      posisi: _s(m['posisi'], '—'),
      catatan: _s(m['catatan']),
      diajukan: _dt(m['diajukan_at']),
      dudi: _s(dudi['nama'], '-'),
      lokasi: _lokasi(dudi),
    );
  }
}

/// Status magang siswa -> dasar gatekeeping halaman Absensi & Jurnal.
class MagangStatus {
  const MagangStatus({this.penempatan, this.pengajuan});

  final Penempatan? penempatan;
  final PengajuanSiswa? pengajuan;

  /// `true` bila siswa punya penempatan aktif (pengajuan sudah di-ACC admin).
  bool get isMagangApproved => penempatan != null;
}

class Jurnal {
  const Jurnal({
    required this.id,
    required this.tanggal,
    required this.kegiatan,
    required this.kendala,
    required this.status,
    required this.catatanGuru,
    required this.foto,
  });

  final String id, kegiatan, kendala, status, catatanGuru;
  final String? foto;
  final DateTime tanggal;

  /// Edit/hapus hanya boleh saat 'menunggu' atau 'ditolak'.
  bool get bisaDiubah => status == 'menunggu' || status == 'ditolak';

  factory Jurnal.fromMap(Map<String, dynamic> m) => Jurnal(
        id: _s(m['id']),
        tanggal: _dt(m['tanggal']) ?? DateTime.now(),
        kegiatan: _s(m['kegiatan']),
        kendala: _s(m['kendala']),
        status: _s(m['status'], 'menunggu'),
        catatanGuru: _s(m['catatan_guru']),
        foto: m['foto_path'] as String?,
      );
}

class AbsensiSiswa {
  const AbsensiSiswa({
    required this.id,
    required this.tanggal,
    required this.status,
    required this.jamMasuk,
    required this.jamKeluar,
    required this.keterangan,
    required this.fotoMasuk,
    required this.fotoPulang,
    required this.autoAlfa,
  });

  final String id, status, keterangan;
  final DateTime tanggal;
  final DateTime? jamMasuk, jamKeluar;
  final String? fotoMasuk, fotoPulang;
  final bool autoAlfa;

  factory AbsensiSiswa.fromMap(Map<String, dynamic> m) => AbsensiSiswa(
        id: _s(m['id']),
        tanggal: _dt(m['tanggal']) ?? DateTime.now(),
        status: _s(m['status'], 'hadir'),
        jamMasuk: _dt(m['jam_masuk']),
        jamKeluar: _dt(m['jam_keluar']),
        keterangan: _s(m['keterangan']),
        fotoMasuk: m['foto_masuk_path'] as String?,
        fotoPulang: m['foto_pulang_path'] as String?,
        autoAlfa: m['auto_alfa'] == true,
      );
}
