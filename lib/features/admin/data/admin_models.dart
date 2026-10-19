String _s(dynamic v, [String d = '']) => v?.toString() ?? d;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

class DashboardStats {
  const DashboardStats({
    this.siswa = 0,
    this.guru = 0,
    this.dudi = 0,
    this.menunggu = 0,
    this.disetujui = 0,
    this.ditolak = 0,
    this.penempatanAktif = 0,
  });

  final int siswa, guru, dudi, menunggu, disetujui, ditolak, penempatanAktif;

  factory DashboardStats.fromMap(Map<String, dynamic> m) => DashboardStats(
        siswa: _i(m['total_siswa']),
        guru: _i(m['total_guru']),
        dudi: _i(m['total_dudi']),
        menunggu: _i(m['permohonan_menunggu']),
        disetujui: _i(m['permohonan_disetujui']),
        ditolak: _i(m['permohonan_ditolak']),
        penempatanAktif: _i(m['penempatan_aktif']),
      );
}

class TrendPoint {
  const TrendPoint(this.bulan, this.pengajuan, this.disetujui);
  final DateTime bulan;
  final int pengajuan, disetujui;

  factory TrendPoint.fromMap(Map<String, dynamic> m) =>
      TrendPoint(_dt(m['bulan']) ?? DateTime.now(), _i(m['pengajuan']), _i(m['disetujui']));
}

class LogEntry {
  const LogEntry({
    required this.id,
    required this.waktu,
    required this.level,
    required this.aksi,
    required this.email,
    required this.role,
    required this.modul,
    required this.ip,
    required this.metadata,
  });

  final int id;
  final DateTime waktu;
  final String level, aksi, email, role, modul, ip;
  final Map<String, dynamic> metadata;

  factory LogEntry.fromMap(Map<String, dynamic> m) => LogEntry(
        id: _i(m['id']),
        waktu: _dt(m['created_at']) ?? DateTime.now(),
        level: _s(m['level'], 'INFO'),
        aksi: _s(m['aksi']),
        email: _s(m['actor_email'], '—'),
        role: _s(m['actor_role'], '—'),
        modul: _s(m['modul'], 'AUTH'),
        ip: _s(m['ip'], '—'),
        metadata: (m['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class SiswaRow {
  const SiswaRow({
    required this.id,
    required this.nis,
    required this.nama,
    required this.email,
    required this.kelas,
    required this.status,
    required this.industri,
    required this.pembimbing,
  });

  final String id, nis, nama, email, kelas, status, industri, pembimbing;

  factory SiswaRow.fromMap(Map<String, dynamic> m) => SiswaRow(
        id: _s(m['id']),
        nis: _s(m['nis']),
        nama: _s(m['nama']),
        email: _s(m['email']),
        kelas: _s(m['kelas'], '—'),
        status: _s(m['status_magang'], 'belum_magang'),
        industri: _s(m['industri'], '—'),
        pembimbing: _s(m['pembimbing'], '—'),
      );
}

class GuruRow {
  const GuruRow({
    required this.id,
    required this.nip,
    required this.nama,
    required this.email,
    required this.jurusan,
    required this.aktif,
    required this.bimbingan,
  });

  final String id, nip, nama, email, jurusan;
  final bool aktif;
  final int bimbingan;

  factory GuruRow.fromMap(Map<String, dynamic> m) => GuruRow(
        id: _s(m['id']),
        nip: _s(m['nip'], '—'),
        nama: _s(m['nama']),
        email: _s(m['email']),
        jurusan: _s(m['jurusan'], '—'),
        aktif: m['is_active'] != false,
        bimbingan: _i(m['bimbingan']),
      );
}

class DudiRow {
  const DudiRow({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.kota,
    required this.bidang,
    required this.pic,
    required this.kontak,
    required this.kuota,
    required this.siswaAktif,
    required this.status,
  });

  final String id, nama, alamat, kota, bidang, pic, kontak, status;
  final int kuota, siswaAktif;

  String get lokasi {
    final parts = [alamat, kota].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  factory DudiRow.fromMap(Map<String, dynamic> m) => DudiRow(
        id: _s(m['id']),
        nama: _s(m['nama']),
        alamat: _s(m['alamat']),
        kota: _s(m['kota']),
        bidang: _s(m['bidang_usaha'], '—'),
        pic: _s(m['kontak_nama'], '—'),
        kontak: _s(m['kontak_telepon'], '—'),
        kuota: _i(m['kuota']),
        siswaAktif: _i(m['siswa_aktif']),
        status: _s(m['status'], 'terverifikasi'),
      );
}

class PenempatanRow {
  const PenempatanRow({
    required this.id,
    required this.siswa,
    required this.nis,
    required this.kelas,
    required this.dudi,
    required this.pembimbing,
    required this.mulai,
    required this.selesai,
    required this.status,
  });

  final String id, siswa, nis, kelas, dudi, pembimbing, status;
  final DateTime? mulai, selesai;

  factory PenempatanRow.fromMap(Map<String, dynamic> m) => PenempatanRow(
        id: _s(m['id']),
        siswa: _s(m['siswa']),
        nis: _s(m['nis']),
        kelas: _s(m['kelas'], '—'),
        dudi: _s(m['dudi']),
        pembimbing: _s(m['pembimbing'], 'Belum ditentukan'),
        mulai: _dt(m['tanggal_mulai']),
        selesai: _dt(m['tanggal_selesai']),
        status: _s(m['status'], 'aktif'),
      );
}

class PengajuanRow {
  const PengajuanRow({
    required this.id,
    required this.siswa,
    required this.nis,
    required this.kelas,
    required this.dudi,
    required this.lokasi,
    required this.pic,
    required this.diajukan,
  });

  final String id, siswa, nis, kelas, dudi, lokasi, pic;
  final DateTime? diajukan;

  factory PengajuanRow.fromMap(Map<String, dynamic> m) => PengajuanRow(
        id: _s(m['id']),
        siswa: _s(m['siswa']),
        nis: _s(m['nis']),
        kelas: _s(m['kelas'], '—'),
        dudi: _s(m['dudi']),
        lokasi: _s(m['lokasi'], '—'),
        pic: _s(m['pic'], '—'),
        diajukan: _dt(m['diajukan_at']),
      );
}

class MonitoringRow {
  const MonitoringRow({
    required this.id,
    required this.siswa,
    required this.kelas,
    required this.dudi,
    required this.pembimbing,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpa,
    required this.jurnal,
    required this.jurnalMinggu,
    required this.status,
    required this.aktivitasTerakhir,
  });

  final String id, siswa, kelas, dudi, pembimbing, status;
  final int hadir, sakit, izin, alpa, jurnal, jurnalMinggu;
  final DateTime? aktivitasTerakhir;

  factory MonitoringRow.fromMap(Map<String, dynamic> m) => MonitoringRow(
        id: _s(m['id']),
        siswa: _s(m['siswa']),
        kelas: _s(m['kelas'], '—'),
        dudi: _s(m['dudi']),
        pembimbing: _s(m['pembimbing'], '—'),
        hadir: _i(m['hadir']),
        sakit: _i(m['sakit']),
        izin: _i(m['izin']),
        alpa: _i(m['alpa']),
        jurnal: _i(m['jurnal']),
        jurnalMinggu: _i(m['jurnal_minggu']),
        status: _s(m['status'], 'normal'),
        aktivitasTerakhir: _dt(m['aktivitas_terakhir']),
      );
}

class KunjunganRow {
  const KunjunganRow({required this.guru, required this.dudi, required this.tanggal, required this.catatan});
  final String guru, dudi, catatan;
  final DateTime? tanggal;

  factory KunjunganRow.fromMap(Map<String, dynamic> m) => KunjunganRow(
        guru: _s(m['guru']),
        dudi: _s(m['dudi']),
        tanggal: _dt(m['tanggal']),
        catatan: _s(m['catatan'], '—'),
      );
}
