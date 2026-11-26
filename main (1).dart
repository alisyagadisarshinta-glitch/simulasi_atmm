// Proyek Mini OOP: VCN mobile (Nama Pengguna + PIN Bebas + Elemen Gerak + Tombol Next)
// Seluruh data rekening, nama pengguna, PIN, kode QR, dan saldo bersifat fiktif untuk simulasi.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

void main() {
  runApp(const VcnMobileApp());
}

enum JalurLayananVcn {
  mVcn,
  klikVcn,
  myVcn,
}

class Transaksi {
  final String kodeRef;
  final String jenis;
  final double nominal;
  final double saldoSebelum;
  final double saldoSesudah;
  final String status;
  final String keterangan;

  Transaksi({
    required this.kodeRef,
    required this.jenis,
    required this.nominal,
    required this.saldoSebelum,
    required this.saldoSesudah,
    required this.status,
    required this.keterangan,
  });
}

class Rekening {
  final String nomorRekening;
  String _pin;
  double _saldo;
  final double batasTarikSekali;
  int _counterRef = 100;
  final List<Transaksi> _riwayat = [];

  Rekening({
    required this.nomorRekening,
    required String pin,
    required double saldoAwal,
    this.batasTarikSekali = 1250000,
  })  : _pin = pin,
        _saldo = saldoAwal >= 0 ? saldoAwal : 0;

  double get saldo => _saldo;

  List<Transaksi> get riwayat => List.unmodifiable(_riwayat);

  String get kodeQrSetor => 'VCN:$nomorRekening:SETOR';
  String get kodeQrTarik => 'VCN:$nomorRekening:TARIK';
  String get kodeQrTransfer => 'VCN:$nomorRekening:TRF';

  static String formatRupiah(double angka) {
    final int bulat = angka.round();
    final String teks = bulat.abs().toString();
    final StringBuffer hasil = StringBuffer();
    for (int i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) {
        hasil.write('.');
      }
      hasil.write(teks[i]);
    }
    return bulat < 0 ? '-${hasil.toString()}' : hasil.toString();
  }

  String _buatKodeRef() {
    _counterRef++;
    return 'VCN-$nomorRekening-$_counterRef';
  }

  bool verifikasiPin(String inputPin) {
    return _pin == inputPin.trim();
  }

  Transaksi cekSaldo() {
    return _catatTransaksi(
      jenis: 'CEK SALDO',
      nominal: 0,
      saldoSebelum: _saldo,
      saldoSesudah: _saldo,
      status: 'BERHASIL',
      keterangan: 'Informasi saldo rekening VCN ditampilkan',
    );
  }

  Transaksi setorTunai(double nominal, {String kanal = 'TUNAI'}) {
    final double sebelum = _saldo;
    if (nominal <= 0) {
      return _catatTransaksi(
        jenis: 'SETOR $kanal',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Nominal setor harus lebih besar dari Rp 0',
      );
    }

    _saldo += nominal;
    return _catatTransaksi(
      jenis: 'SETOR $kanal',
      nominal: nominal,
      saldoSebelum: sebelum,
      saldoSesudah: _saldo,
      status: 'BERHASIL',
      keterangan: 'Setoran $kanal berhasil masuk ke rekening VCN',
    );
  }

  Transaksi tarikTunai(double nominal, {String kanal = 'TUNAI'}) {
    final double sebelum = _saldo;
    if (nominal <= 0) {
      return _catatTransaksi(
        jenis: 'TARIK $kanal',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Nominal tarik harus lebih besar dari Rp 0',
      );
    }

    if (nominal > batasTarikSekali) {
      return _catatTransaksi(
        jenis: 'TARIK $kanal',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan:
            'Melebihi batas tarik sekali (Rp ${formatRupiah(batasTarikSekali)})',
      );
    }

    if (nominal > _saldo) {
      return _catatTransaksi(
        jenis: 'TARIK $kanal',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Saldo rekening tidak mencukupi',
      );
    }

    _saldo -= nominal;
    return _catatTransaksi(
      jenis: 'TARIK $kanal',
      nominal: nominal,
      saldoSebelum: sebelum,
      saldoSesudah: _saldo,
      status: 'BERHASIL',
      keterangan: 'Penarikan $kanal disetujui',
    );
  }

  Transaksi kirimTransfer(
    String tujuanRekening,
    double nominal, {
    String kanal = 'TRANSFER',
  }) {
    final double sebelum = _saldo;
    if (tujuanRekening.trim().isEmpty) {
      return _catatTransaksi(
        jenis: '$kanal KELUAR',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Nomor rekening tujuan belum diisi',
      );
    }

    if (tujuanRekening.trim() == nomorRekening) {
      return _catatTransaksi(
        jenis: '$kanal KELUAR',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Tidak dapat transfer ke rekening sendiri',
      );
    }

    if (nominal <= 0) {
      return _catatTransaksi(
        jenis: '$kanal KELUAR',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Nominal transfer harus lebih besar dari Rp 0',
      );
    }

    if (nominal > _saldo) {
      return _catatTransaksi(
        jenis: '$kanal KELUAR',
        nominal: nominal,
        saldoSebelum: sebelum,
        saldoSesudah: _saldo,
        status: 'DITOLAK',
        keterangan: 'Saldo tidak cukup untuk transfer',
      );
    }

    _saldo -= nominal;
    return _catatTransaksi(
      jenis: '$kanal KELUAR',
      nominal: nominal,
      saldoSebelum: sebelum,
      saldoSesudah: _saldo,
      status: 'BERHASIL',
      keterangan: 'Transfer ke rekening ${tujuanRekening.trim()}',
    );
  }

  void terimaTransfer(
    String asalRekening,
    double nominal, {
    String kanal = 'TRANSFER',
  }) {
    if (nominal <= 0) return;
    final double sebelum = _saldo;
    _saldo += nominal;
    _catatTransaksi(
      jenis: '$kanal MASUK',
      nominal: nominal,
      saldoSebelum: sebelum,
      saldoSesudah: _saldo,
      status: 'BERHASIL',
      keterangan: 'Terima transfer dari rekening $asalRekening',
    );
  }

  String gantiPin(String pinLama, String pinBaru) {
    final String bersihBaru = pinBaru.trim();
    if (_pin != pinLama.trim()) {
      return 'Ganti PIN gagal: PIN lama tidak sesuai.';
    }
    if (bersihBaru.isEmpty) {
      return 'Ganti PIN gagal: PIN baru tidak boleh kosong.';
    }
    _pin = bersihBaru;
    _catatTransaksi(
      jenis: 'GANTI PIN',
      nominal: 0,
      saldoSebelum: _saldo,
      saldoSesudah: _saldo,
      status: 'BERHASIL',
      keterangan: 'PIN rekening VCN diperbarui',
    );
    return 'PIN baru berhasil disimpan.';
  }

  Transaksi _catatTransaksi({
    required String jenis,
    required double nominal,
    required double saldoSebelum,
    required double saldoSesudah,
    required String status,
    required String keterangan,
  }) {
    final Transaksi trx = Transaksi(
      kodeRef: _buatKodeRef(),
      jenis: jenis,
      nominal: nominal,
      saldoSebelum: saldoSebelum,
      saldoSesudah: saldoSesudah,
      status: status,
      keterangan: keterangan,
    );
    _riwayat.insert(0, trx);
    return trx;
  }
}

class AkunVcn {
  final String namaPengguna;
  final Rekening rekening;
  AkunVcn({required this.namaPengguna, required this.rekening});
}

class SistemVcnMobile {
  final String namaBank;
  final int maksimalPercobaanPin;
  final List<AkunVcn> daftarAkun;

  AkunVcn? _akunAktif;
  int _percobaanGagal = 0;
  bool _terblokirSesi = false;
  int _urutRekening = 5501001;

  SistemVcnMobile({
    this.namaBank = 'VCN',
    List<AkunVcn>? daftarAkun,
    this.maksimalPercobaanPin = 3,
  }) : daftarAkun = daftarAkun ?? [];

  AkunVcn? get akunAktif => _akunAktif;
  int get percobaanGagal => _percobaanGagal;
  bool get terblokirSesi => _terblokirSesi;

  String saranNomorRekeningBaru() {
    while (true) {
      final String kandidat = _urutRekening.toString();
      _urutRekening++;
      if (cariRekening(kandidat) == null) {
        return kandidat;
      }
    }
  }

  String daftarAkunBaru({
    required String namaPengguna,
    required String noRekening,
    required String pinBebas,
    required double saldoAwal,
  }) {
    final String namaBersih = namaPengguna.trim();
    final String rekBersih = noRekening.trim();
    final String pinBersih = pinBebas.trim();

    if (namaBersih.isEmpty) {
      return 'Pendaftaran gagal: Nama pengguna wajib diisi.';
    }
    if (rekBersih.length < 4 || int.tryParse(rekBersih) == null) {
      return 'Pendaftaran gagal: Nomor rekening harus angka minimal 4 digit.';
    }
    if (cariRekening(rekBersih) != null) {
      return 'Pendaftaran gagal: Nomor rekening $rekBersih sudah terdaftar.';
    }
    if (pinBersih.isEmpty) {
      return 'Pendaftaran gagal: Isi PIN bebas pilihan Anda terlebih dahulu.';
    }
    if (saldoAwal < 0) {
      return 'Pendaftaran gagal: Saldo awal tidak boleh negatif.';
    }

    daftarAkun.add(
      AkunVcn(
        namaPengguna: namaBersih,
        rekening: Rekening(
          nomorRekening: rekBersih,
          pin: pinBersih,
          saldoAwal: saldoAwal,
        ),
      ),
    );

    return 'Rekening $rekBersih atas nama $namaBersih di $namaBank berhasil dibuat. Silakan klik MASUK.';
  }

  String pastikanAdaRekeningRekan(String rekeningSaatIni) {
    for (final AkunVcn a in daftarAkun) {
      if (a.rekening.nomorRekening != rekeningSaatIni) {
        return a.rekening.nomorRekening;
      }
    }
    final String rekBaru = saranNomorRekeningBaru();
    daftarAkun.add(
      AkunVcn(
        namaPengguna: 'Pengguna Uji',
        rekening: Rekening(
          nomorRekening: rekBaru,
          pin: '1234',
          saldoAwal: 250000,
        ),
      ),
    );
    return rekBaru;
  }

  Rekening? cariRekening(String noRekening) {
    final String bersih = noRekening.trim();
    for (final AkunVcn a in daftarAkun) {
      if (a.rekening.nomorRekening == bersih) {
        return a.rekening;
      }
    }
    return null;
  }

  Rekening? cariRekeningDariQrTransfer(String qrCode) {
    final String bersih = qrCode.trim().toUpperCase();
    if (bersih.startsWith('VCN:') && bersih.endsWith(':TRF')) {
      final List<String> bagian = bersih.split(':');
      if (bagian.length >= 2) {
        return cariRekening(bagian[1]);
      }
    }
    for (final AkunVcn a in daftarAkun) {
      if (a.rekening.kodeQrTransfer.toUpperCase() == bersih ||
          a.rekening.nomorRekening == bersih) {
        return a.rekening;
      }
    }
    return null;
  }

  String login(String noRekening, String pin) {
    if (_terblokirSesi) {
      return 'AKSES TERKUNCI: Salah PIN $maksimalPercobaanPin kali.';
    }

    final Rekening? rek = cariRekening(noRekening);
    if (rek == null) {
      return 'REKENING BELUM TERDAFTAR: Buka rekening baru terlebih dahulu.';
    }

    if (rek.verifikasiPin(pin)) {
      for (final AkunVcn a in daftarAkun) {
        if (a.rekening.nomorRekening == rek.nomorRekening) {
          _akunAktif = a;
          break;
        }
      }
      _percobaanGagal = 0;
      final String nama = _akunAktif?.namaPengguna ?? rek.nomorRekening;
      return 'Berhasil masuk ke $namaBank • $nama (${rek.nomorRekening})';
    } else {
      _percobaanGagal++;
      final int sisa = maksimalPercobaanPin - _percobaanGagal;
      if (sisa <= 0) {
        _terblokirSesi = true;
        return 'PIN SALAH: Batas percobaan habis ($maksimalPercobaanPin/$maksimalPercobaanPin).';
      }
      return 'PIN SALAH: Sisa kesempatan masuk $sisa kali lagi.';
    }
  }

  String prosesTransfer({
    required String noRekeningTujuan,
    required double nominal,
    String kanal = 'TRANSFER',
  }) {
    final AkunVcn? aktif = _akunAktif;
    if (aktif == null) return 'Tidak ada sesi aktif.';

    final Rekening? tujuan = cariRekening(noRekeningTujuan);
    if (tujuan == null) {
      aktif.rekening._catatTransaksi(
        jenis: '$kanal KELUAR',
        nominal: nominal,
        saldoSebelum: aktif.rekening.saldo,
        saldoSesudah: aktif.rekening.saldo,
        status: 'DITOLAK',
        keterangan: 'Rekening tujuan ${noRekeningTujuan.trim()} tidak terdaftar',
      );
      return '$kanal ditolak: Rekening tujuan tidak terdaftar.';
    }

    final Transaksi hasil = aktif.rekening.kirimTransfer(
      noRekeningTujuan,
      nominal,
      kanal: kanal,
    );
    if (hasil.status == 'BERHASIL') {
      tujuan.terimaTransfer(
        aktif.rekening.nomorRekening,
        nominal,
        kanal: kanal,
      );
      return '$kanal Rp ${Rekening.formatRupiah(nominal)} ke rek ${tujuan.nomorRekening} berhasil.';
    }
    return '$kanal ditolak: ${hasil.keterangan}.';
  }

  String prosesQrCardless({
    required String kodeQr,
    required double nominal,
  }) {
    final AkunVcn? aktif = _akunAktif;
    if (aktif == null) return 'Tidak ada sesi aktif.';

    final String qr = kodeQr.trim().toUpperCase();
    final Rekening rek = aktif.rekening;

    if (qr == rek.kodeQrSetor.toUpperCase() ||
        qr.endsWith(':${rek.nomorRekening}:SETOR')) {
      final Transaksi trx = rek.setorTunai(nominal, kanal: 'QR');
      return trx.status == 'BERHASIL'
          ? 'Setor QR Rp ${Rekening.formatRupiah(nominal)} berhasil (${trx.kodeRef}).'
          : 'Setor QR ditolak: ${trx.keterangan}.';
    }

    if (qr == rek.kodeQrTarik.toUpperCase() ||
        qr.endsWith(':${rek.nomorRekening}:TARIK')) {
      final Transaksi trx = rek.tarikTunai(nominal, kanal: 'QR');
      return trx.status == 'BERHASIL'
          ? 'Tarik QR Rp ${Rekening.formatRupiah(nominal)} berhasil (${trx.kodeRef}).'
          : 'Tarik QR ditolak: ${trx.keterangan}.';
    }

    return 'Kode QR tidak sesuai dengan rekening ${rek.nomorRekening}.';
  }

  void logout() {
    _akunAktif = null;
  }
}

class _PaletPastelPink {
  static const Color latarAtas = Color(0xFFFFF5F8);
  static const Color latarTengah = Color(0xFFFFE0EC);
  static const Color latarBawah = Color(0xFFFBC9DC);

  static const Color tombolTerang = Color(0xFFFFC9DE);
  static const Color tombolSedang = Color(0xFFF79EC2);
  static const Color tombolDalam = Color(0xFFE06B9E);

  static const Color permukaanKartu = Color(0xFFFFFAF7);
  static const Color borderPink = Color(0xFFF4B6D0);
  static const Color teksGelap = Color(0xFF5A1F3A);
  static const Color teksSedang = Color(0xFF883C5E);
  static const Color badgePink = Color(0xFFFFE7F0);
}

class VcnMobileApp extends StatelessWidget {
  const VcnMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VCN mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _PaletPastelPink.tombolDalam,
          primary: _PaletPastelPink.tombolDalam,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFFB57C96), fontSize: 13.5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _PaletPastelPink.borderPink),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _PaletPastelPink.borderPink),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: _PaletPastelPink.tombolDalam,
              width: 1.8,
            ),
          ),
        ),
      ),
      home: const LayarMenuVcnMobile(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ELEMEN GERAK LUCU & RAPI (BUBBLE PASTEL + SPARKLE MELAYANG)
/// ---------------------------------------------------------------------------
class _LatarGerakLucu extends StatefulWidget {
  final Widget child;
  const _LatarGerakLucu({required this.child});

  @override
  State<_LatarGerakLucu> createState() => _LatarGerakLucuState();
}

class _LatarGerakLucuState extends State<_LatarGerakLucu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final double phase = _ctrl.value * 2 * math.pi;
        final double y1 = math.sin(phase) * 14;
        final double x1 = math.cos(phase * 0.7) * 10;
        final double y2 = math.cos(phase * 1.1) * 16;
        final double x2 = math.sin(phase * 0.8) * 12;
        final double rotStar = math.sin(phase) * 0.35;
        final double scaleStar = 0.9 + (math.sin(phase * 2).abs() * 0.22);

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _PaletPastelPink.latarAtas,
                _PaletPastelPink.latarTengah,
                _PaletPastelPink.latarBawah,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 48 + y1,
                left: 22 + x1,
                child: IgnorePointer(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.48),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 112 + y2,
                right: 26 + x2,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: rotStar,
                    child: Transform.scale(
                      scale: scaleStar,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 26,
                        color: const Color(0xFFE06B9E).withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 96 - y1,
                left: 34 - x2,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: -rotStar,
                    child: Icon(
                      Icons.favorite,
                      size: 20,
                      color: const Color(0xFFE06B9E).withValues(alpha: 0.34),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 52 + y2,
                right: 30 - x1,
                child: IgnorePointer(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.42),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ---------------------------------------------------------------------------
/// TOMBOL NEXT LUCU (MEMANTUL HALUS + PANAH GESER + EFEK TEKAN)
/// ---------------------------------------------------------------------------
class _TombolNextLucu extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool sekunder;

  const _TombolNextLucu({
    required this.label,
    required this.onTap,
    this.sekunder = false,
  });

  @override
  State<_TombolNextLucu> createState() => _TombolNextLucuState();
}

class _TombolNextLucuState extends State<_TombolNextLucu>
    with SingleTickerProviderStateMixin {
  bool _ditekan = false;
  late final AnimationController _gerakCtrl;

  @override
  void initState() {
    super.initState();
    _gerakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gerakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool aktif = widget.onTap != null;

    return AnimatedBuilder(
      animation: _gerakCtrl,
      builder: (context, _) {
        final double pantulY =
            aktif ? -math.sin(_gerakCtrl.value * math.pi) * 2.5 : 0;
        final double geserX = aktif ? _gerakCtrl.value * 5 : 0;

        return Transform.translate(
          offset: Offset(0, pantulY),
          child: AnimatedScale(
            scale: _ditekan ? 0.955 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: aktif
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE06B9E).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onTap,
                  onHighlightChanged: (v) {
                    if (aktif) setState(() => _ditekan = v);
                  },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: widget.sekunder
                          ? const LinearGradient(
                              colors: [Color(0xFFFFF9FC), Color(0xFFFFDFEC)],
                            )
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _PaletPastelPink.tombolTerang,
                                _PaletPastelPink.tombolSedang,
                                _PaletPastelPink.tombolDalam,
                              ],
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 15,
                          color: widget.sekunder
                              ? _PaletPastelPink.tombolDalam
                              : Colors.white,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.sekunder
                                  ? _PaletPastelPink.teksGelap
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.translate(
                          offset: Offset(geserX, 0),
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: widget.sekunder
                                  ? _PaletPastelPink.badgePink
                                  : Colors.white.withValues(alpha: 0.28),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: widget.sekunder
                                  ? _PaletPastelPink.teksGelap
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// TRANSISI HALUS SAAT GANTI FITUR
/// ---------------------------------------------------------------------------
Widget _transisiKontenHalus(Widget child, {Key? key}) {
  return AnimatedSwitcher(
    key: key,
    duration: const Duration(milliseconds: 260),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (w, anim) {
      final Animation<Offset> geser = Tween<Offset>(
        begin: const Offset(0.04, 0.02),
        end: Offset.zero,
      ).animate(anim);
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(position: geser, child: w),
      );
    },
    child: child,
  );
}

/// ---------------------------------------------------------------------------
/// WIDGET QR CODE PAKAI `package:qr` + BARCODE
/// ---------------------------------------------------------------------------
class _KanvasQrPaket extends StatelessWidget {
  final String dataKode;
  final double ukuran;

  const _KanvasQrPaket({
    required this.dataKode,
    this.ukuran = 176,
  });

  @override
  Widget build(BuildContext context) {
    final String isi =
        dataKode.trim().isEmpty ? 'VCN:0000:SETOR' : dataKode.trim();
    final QrCode qrCode = QrCode.fromData(
      data: isi,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final QrImage qrImage = QrImage(qrCode);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PaletPastelPink.borderPink, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A883C5E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(ukuran, ukuran),
        painter: _QrPaketPainter(qrImage),
      ),
    );
  }
}

class _QrPaketPainter extends CustomPainter {
  final QrImage qrImage;
  _QrPaketPainter(this.qrImage);

  @override
  void paint(Canvas canvas, Size size) {
    final int count = qrImage.moduleCount;
    final double cell = size.width / count;
    final Paint hitam = Paint()..color = Colors.black;

    for (int x = 0; x < count; x++) {
      for (int y = 0; y < count; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            hitam,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPaketPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage;
}

class _KanvasBarcode extends StatelessWidget {
  final String dataKode;

  const _KanvasBarcode({required this.dataKode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PaletPastelPink.borderPink),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            width: double.infinity,
            child: CustomPaint(painter: _BarcodePainter(dataKode)),
          ),
          const SizedBox(height: 6),
          Text(
            dataKode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PaletPastelPink.teksGelap,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final String kode;
  _BarcodePainter(this.kode);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.black;
    int seed = 1337;
    for (int i = 0; i < kode.length; i++) {
      seed = (seed * 31 + kode.codeUnitAt(i)) & 0x7fffffff;
    }

    double x = 2;
    int idx = 0;
    while (x < size.width - 4) {
      final int v = (seed + idx * 73) & 0x7fffffff;
      final double w = (v % 3 + 1) * 1.6;
      if ((v % 2) == 0) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w + 1.8;
      idx++;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) =>
      oldDelegate.kode != kode;
}

/// ---------------------------------------------------------------------------
/// 1. LAYAR AWAL VCN MOBILE
/// ---------------------------------------------------------------------------
class LayarMenuVcnMobile extends StatefulWidget {
  const LayarMenuVcnMobile({super.key});

  @override
  State<LayarMenuVcnMobile> createState() => _LayarMenuVcnMobileState();
}

class _LayarMenuVcnMobileState extends State<LayarMenuVcnMobile> {
  late final SistemVcnMobile _vcn;

  @override
  void initState() {
    super.initState();
    _vcn = SistemVcnMobile(namaBank: 'VCN', daftarAkun: []);
  }

  void _bukaJalur(JalurLayananVcn jalur, {String? rekeningAwal}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanMasukVcnMobile(
          vcn: _vcn,
          jalur: jalur,
          rekeningAwal: rekeningAwal,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _bukaDaftar({String? rekeningAwal}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanBukaRekeningVcn(
          vcn: _vcn,
          rekeningAwal: rekeningAwal,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _tampilkanInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _PaletPastelPink.permukaanKartu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Fungsi Menu ${_vcn.namaBank} mobile',
          style: const TextStyle(
            color: _PaletPastelPink.teksGelap,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          '• m-VCN: Transfer, Tarik/Setor Tunai & QRIS.\n'
          '• KlikVCN: Mutasi, Ganti PIN & Transfer.\n'
          '• myVCN (NEW!): QRIS, Barcode & Saldo.',
          style: TextStyle(color: _PaletPastelPink.teksSedang, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: _PaletPastelPink.tombolDalam,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _kotakIkonKecil(String teksIkon) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x265A1F3A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        teksIkon,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _PaletPastelPink.teksGelap,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _tombolPastel({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? borderRadius,
  }) {
    final BorderRadius radius = borderRadius ?? BorderRadius.circular(14);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F883C5E),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _PaletPastelPink.tombolTerang,
                  _PaletPastelPink.tombolSedang,
                  _PaletPastelPink.tombolDalam,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AkunVcn? akunTerakhir =
        _vcn.daftarAkun.isNotEmpty ? _vcn.daftarAkun.last : null;
    final String rekAwal = akunTerakhir?.rekening.nomorRekening ?? '';

    return Scaffold(
      body: _LatarGerakLucu(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 14),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: _tampilkanInfo,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.75),
                    ),
                    icon: const Icon(
                      Icons.info_outline,
                      color: _PaletPastelPink.teksGelap,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _vcn.namaBank,
                                style: const TextStyle(
                                  color: _PaletPastelPink.teksGelap,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                'mobile',
                                style: TextStyle(
                                  color: _PaletPastelPink.teksSedang,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A883C5E),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _tombolPastel(
                                  onTap: () => _bukaJalur(JalurLayananVcn.mVcn,
                                      rekeningAwal: rekAwal),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    child: Row(
                                      children: [
                                        _kotakIkonKecil('m-${_vcn.namaBank}'),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'm-${_vcn.namaBank}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Transfer, Tarik/Setor & QRIS',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.white),
                                _tombolPastel(
                                  onTap: () => _bukaJalur(
                                      JalurLayananVcn.klikVcn,
                                      rekeningAwal: rekAwal),
                                  borderRadius: BorderRadius.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    child: Row(
                                      children: [
                                        _kotakIkonKecil('Klik\n${_vcn.namaBank}'),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Klik${_vcn.namaBank}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Mutasi, Ganti PIN & Transfer',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.white),
                                _tombolPastel(
                                  onTap: () => _bukaJalur(JalurLayananVcn.myVcn,
                                      rekeningAwal: rekAwal),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(14),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    child: Row(
                                      children: [
                                        _kotakIkonKecil('my\n${_vcn.namaBank}'),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'my${_vcn.namaBank}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 19,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _PaletPastelPink
                                                          .badgePink,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Text(
                                                      'NEW!',
                                                      style: TextStyle(
                                                        color: _PaletPastelPink
                                                            .teksGelap,
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'QRIS, Barcode & Saldo',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TombolNextLucu(
                            label: 'Next • Buka Rekening Baru',
                            onTap: () => _bukaDaftar(),
                          ),
                          const SizedBox(height: 11),
                          _TombolNextLucu(
                            label: 'Next • QRIS & Barcode',
                            sekunder: true,
                            onTap: () => _bukaJalur(JalurLayananVcn.myVcn,
                                rekeningAwal: rekAwal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Text(
                  '${_vcn.namaBank} mobile • Simulasi Layanan Rekening & Transaksi Digital.\nSeluruh saldo, nama pengguna, nomor rekening, dan PIN bersifat simulasi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _PaletPastelPink.teksSedang,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 2. HALAMAN BUKA REKENING BARU (NAMA PENGGUNA + PIN BEBAS + SALDO AWAL)
/// ---------------------------------------------------------------------------
class HalamanBukaRekeningVcn extends StatefulWidget {
  final SistemVcnMobile vcn;
  final String? rekeningAwal;

  const HalamanBukaRekeningVcn({
    super.key,
    required this.vcn,
    this.rekeningAwal,
  });

  @override
  State<HalamanBukaRekeningVcn> createState() => _HalamanBukaRekeningVcnState();
}

class _HalamanBukaRekeningVcnState extends State<HalamanBukaRekeningVcn> {
  late final TextEditingController _rekController;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _pinBebasController = TextEditingController();
  final TextEditingController _saldoController =
      TextEditingController(text: '500000');

  String _pesan =
      'Isi nama pengguna, nomor rekening, dan PIN bebas sesuai keinginan Anda.';
  String? _rekBerhasil;

  @override
  void initState() {
    super.initState();
    _rekController = TextEditingController(
      text: widget.rekeningAwal ?? widget.vcn.saranNomorRekeningBaru(),
    );
  }

  @override
  void dispose() {
    _rekController.dispose();
    _namaController.dispose();
    _pinBebasController.dispose();
    _saldoController.dispose();
    super.dispose();
  }

  void _daftar() {
    final String bersih = _saldoController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final double? saldo = double.tryParse(bersih);
    if (saldo == null) {
      setState(() => _pesan = 'Saldo awal harus berupa angka.');
      return;
    }

    final String rekDiminta = _rekController.text.trim();
    final String hasil = widget.vcn.daftarAkunBaru(
      namaPengguna: _namaController.text,
      noRekening: rekDiminta,
      pinBebas: _pinBebasController.text,
      saldoAwal: saldo,
    );

    setState(() {
      _pesan = hasil;
      if (hasil.toLowerCase().contains('berhasil')) {
        _rekBerhasil = rekDiminta;
        _pinBebasController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _LatarGerakLucu(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.75),
                          ),
                          icon: const Icon(Icons.arrow_back,
                              color: _PaletPastelPink.teksGelap),
                        ),
                        Text(
                          '${widget.vcn.namaBank} • BUKA REKENING',
                          style: const TextStyle(
                            color: _PaletPastelPink.teksGelap,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _PaletPastelPink.permukaanKartu
                            .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18883C5E),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: _PaletPastelPink.badgePink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _pesan,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _PaletPastelPink.teksGelap,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _namaController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Nama Pengguna',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _rekController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Nomor Rekening',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _rekController.text =
                                        widget.vcn.saranNomorRekeningBaru();
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _PaletPastelPink.tombolDalam,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'AUTO',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinBebasController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'PIN Bebas (Terserah Anda)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _saldoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Saldo Awal Simulasi',
                              prefixText: 'Rp ',
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _daftar,
                            style: FilledButton.styleFrom(
                              backgroundColor: _PaletPastelPink.tombolDalam,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'DAFTAR REKENING',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (_rekBerhasil != null) ...[
                            const SizedBox(height: 12),
                            _TombolNextLucu(
                              label: 'Next • Ke Halaman Masuk',
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HalamanMasukVcnMobile(
                                      vcn: widget.vcn,
                                      jalur: JalurLayananVcn.mVcn,
                                      rekeningAwal: _rekBerhasil,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 3. HALAMAN MASUK (VCN + TOMBOL MASUK)
/// ---------------------------------------------------------------------------
class HalamanMasukVcnMobile extends StatefulWidget {
  final SistemVcnMobile vcn;
  final JalurLayananVcn jalur;
  final String? rekeningAwal;

  const HalamanMasukVcnMobile({
    super.key,
    required this.vcn,
    required this.jalur,
    this.rekeningAwal,
  });

  @override
  State<HalamanMasukVcnMobile> createState() => _HalamanMasukVcnMobileState();
}

class _HalamanMasukVcnMobileState extends State<HalamanMasukVcnMobile> {
  late final TextEditingController _rekController;
  final TextEditingController _pinController = TextEditingController();

  String _pesan = 'Masukkan nomor rekening dan PIN, lalu tekan MASUK.';

  String get _labelJalur {
    switch (widget.jalur) {
      case JalurLayananVcn.mVcn:
        return 'm-${widget.vcn.namaBank}';
      case JalurLayananVcn.klikVcn:
        return 'Klik${widget.vcn.namaBank}';
      case JalurLayananVcn.myVcn:
        return 'my${widget.vcn.namaBank}';
    }
  }

  @override
  void initState() {
    super.initState();
    final String awal = widget.rekeningAwal ??
        (widget.vcn.daftarAkun.isNotEmpty
            ? widget.vcn.daftarAkun.last.rekening.nomorRekening
            : '');
    _rekController = TextEditingController(text: awal);
  }

  @override
  void dispose() {
    _rekController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _masuk() {
    final String hasil =
        widget.vcn.login(_rekController.text, _pinController.text);
    final AkunVcn? aktif = widget.vcn.akunAktif;
    _pinController.clear();

    if (aktif != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HalamanPenggunaVcnMobile(
            vcn: widget.vcn,
            akun: aktif,
            jalur: widget.jalur,
            pesanAwal: hasil,
          ),
        ),
      );
    } else {
      setState(() => _pesan = hasil);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _LatarGerakLucu(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.75),
                          ),
                          icon: const Icon(Icons.arrow_back,
                              color: _PaletPastelPink.teksGelap),
                        ),
                        Text(
                          '${widget.vcn.namaBank} • $_labelJalur',
                          style: const TextStyle(
                            color: _PaletPastelPink.teksGelap,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _PaletPastelPink.permukaanKartu
                            .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18883C5E),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: _PaletPastelPink.badgePink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _pesan,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _PaletPastelPink.teksGelap,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _rekController,
                            keyboardType: TextInputType.number,
                            enabled: !widget.vcn.terblokirSesi,
                            decoration: const InputDecoration(
                              hintText: 'Nomor Rekening',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinController,
                            obscureText: true,
                            enabled: !widget.vcn.terblokirSesi,
                            onSubmitted: (_) => _masuk(),
                            decoration: const InputDecoration(
                              hintText: 'PIN',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TombolNextLucu(
                            label: 'MASUK',
                            onTap: widget.vcn.terblokirSesi ? null : _masuk,
                          ),
                          const SizedBox(height: 10),
                          _TombolNextLucu(
                            label: 'Next • Buka Rekening Baru',
                            sekunder: true,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HalamanBukaRekeningVcn(vcn: widget.vcn),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 4. HALAMAN PENGGUNA SETELAH MASUK (FITUR SESUAI LKPD + TOMBOL & GERAK)
/// ---------------------------------------------------------------------------
enum _MenuVcnPengguna {
  transfer,
  tarik,
  setor,
  qris,
  gantiPin,
  mutasi,
}

class HalamanPenggunaVcnMobile extends StatefulWidget {
  final SistemVcnMobile vcn;
  final AkunVcn akun;
  final JalurLayananVcn jalur;
  final String pesanAwal;

  const HalamanPenggunaVcnMobile({
    super.key,
    required this.vcn,
    required this.akun,
    required this.jalur,
    required this.pesanAwal,
  });

  @override
  State<HalamanPenggunaVcnMobile> createState() =>
      _HalamanPenggunaVcnMobileState();
}

class _HalamanPenggunaVcnMobileState extends State<HalamanPenggunaVcnMobile> {
  late _MenuVcnPengguna _menu;
  late String _pesan;
  bool _tampilkanSaldo = true;

  String _modeQr = 'SETOR';

  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _kodeQrAktifController = TextEditingController();
  final TextEditingController _pinLamaController = TextEditingController();
  final TextEditingController _pinBaruController = TextEditingController();

  @override
  void initState() {
    super.initState();
    switch (widget.jalur) {
      case JalurLayananVcn.mVcn:
        _menu = _MenuVcnPengguna.transfer;
        break;
      case JalurLayananVcn.klikVcn:
        _menu = _MenuVcnPengguna.mutasi;
        break;
      case JalurLayananVcn.myVcn:
        _menu = _MenuVcnPengguna.qris;
        break;
    }

    _pesan = widget.pesanAwal;
    _kodeQrAktifController.text = widget.akun.rekening.kodeQrSetor;

    for (final AkunVcn a in widget.vcn.daftarAkun) {
      if (a.rekening.nomorRekening != widget.akun.rekening.nomorRekening) {
        _tujuanController.text = a.rekening.nomorRekening;
        break;
      }
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _tujuanController.dispose();
    _kodeQrAktifController.dispose();
    _pinLamaController.dispose();
    _pinBaruController.dispose();
    super.dispose();
  }

  void _lanjutMenuBerikutnya() {
    final List<_MenuVcnPengguna> urutan = _MenuVcnPengguna.values;
    final int idx = urutan.indexOf(_menu);
    final _MenuVcnPengguna berikutnya = urutan[(idx + 1) % urutan.length];
    setState(() => _menu = berikutnya);
  }

  void _pilihModeQr(String mode) {
    final Rekening rek = widget.akun.rekening;
    setState(() {
      _modeQr = mode;
      if (mode == 'SETOR') {
        _kodeQrAktifController.text = rek.kodeQrSetor;
      } else if (mode == 'TARIK') {
        _kodeQrAktifController.text = rek.kodeQrTarik;
      } else {
        AkunVcn? rekan;
        for (final AkunVcn a in widget.vcn.daftarAkun) {
          if (a.rekening.nomorRekening != rek.nomorRekening) {
            rekan = a;
            break;
          }
        }
        _kodeQrAktifController.text =
            rekan?.rekening.kodeQrTransfer ?? rek.kodeQrTransfer;
      }
    });
  }

  void _isiDataUjiLkpd() {
    final Rekening rek = widget.akun.rekening;
    final String rekRekan =
        widget.vcn.pastikanAdaRekeningRekan(rek.nomorRekening);
    setState(() {
      _tujuanController.text = rekRekan;
      _nominalController.text = '50000';
      if (_menu == _MenuVcnPengguna.qris) {
        if (_modeQr == 'TRANSFER') {
          _kodeQrAktifController.text = 'VCN:$rekRekan:TRF';
        } else if (_modeQr == 'TARIK') {
          _kodeQrAktifController.text = rek.kodeQrTarik;
        } else {
          _kodeQrAktifController.text = rek.kodeQrSetor;
        }
      }
      _pesan =
          'Data uji LKPD terisi: Nominal Rp 50.000 • Rekening uji $rekRekan.';
    });
  }

  void _bukaScannerSimulasi() {
    final Rekening rek = widget.akun.rekening;
    final List<String> opsiQr = [
      rek.kodeQrSetor,
      rek.kodeQrTarik,
      for (final AkunVcn a in widget.vcn.daftarAkun)
        if (a.rekening.nomorRekening != rek.nomorRekening)
          a.rekening.kodeQrTransfer,
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _PaletPastelPink.permukaanKartu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: _PaletPastelPink.teksGelap,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih hasil scan QR di bawah untuk mengisi otomatis:',
              style: TextStyle(color: _PaletPastelPink.teksSedang, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ...opsiQr.map(
              (kode) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _kodeQrAktifController.text = kode;
                      if (kode.endsWith(':TARIK')) {
                        _modeQr = 'TARIK';
                      } else if (kode.endsWith(':TRF')) {
                        _modeQr = 'TRANSFER';
                      } else {
                        _modeQr = 'SETOR';
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(kode),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  double? _bacaNominal() {
    final String bersih = _nominalController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(bersih);
  }

  void _aksiTransfer() {
    final double? nominal = _bacaNominal();
    setState(() {
      if (nominal == null) {
        _pesan = 'Nominal tidak valid.';
        return;
      }
      _pesan = widget.vcn.prosesTransfer(
        noRekeningTujuan: _tujuanController.text,
        nominal: nominal,
      );
      if (_pesan.toLowerCase().contains('berhasil')) _nominalController.clear();
    });
  }

  void _aksiTarik() {
    final double? nominal = _bacaNominal();
    setState(() {
      if (nominal == null) {
        _pesan = 'Nominal tidak valid.';
        return;
      }
      final Transaksi trx = widget.akun.rekening.tarikTunai(nominal);
      _pesan = trx.status == 'BERHASIL'
          ? 'Tarik Rp ${Rekening.formatRupiah(nominal)} berhasil (${trx.kodeRef}).'
          : 'Tarik ditolak: ${trx.keterangan}.';
      if (trx.status == 'BERHASIL') _nominalController.clear();
    });
  }

  void _aksiSetor() {
    final double? nominal = _bacaNominal();
    setState(() {
      if (nominal == null) {
        _pesan = 'Nominal tidak valid.';
        return;
      }
      final Transaksi trx = widget.akun.rekening.setorTunai(nominal);
      _pesan = trx.status == 'BERHASIL'
          ? 'Setor Rp ${Rekening.formatRupiah(nominal)} berhasil (${trx.kodeRef}).'
          : 'Setor ditolak: ${trx.keterangan}.';
      if (trx.status == 'BERHASIL') _nominalController.clear();
    });
  }

  void _aksiProsesQr() {
    final double? nominal = _bacaNominal();
    setState(() {
      if (nominal == null) {
        _pesan = 'Nominal tidak valid.';
        return;
      }
      final String kode = _kodeQrAktifController.text.trim();
      if (_modeQr == 'TRANSFER') {
        final Rekening? target = widget.vcn.cariRekeningDariQrTransfer(kode);
        if (target == null) {
          _pesan =
              'Kode QR tujuan tidak terdaftar. Klik "Isi Uji" untuk membuat rekening uji.';
          return;
        }
        _pesan = widget.vcn.prosesTransfer(
          noRekeningTujuan: target.nomorRekening,
          nominal: nominal,
          kanal: 'QRIS',
        );
      } else {
        _pesan = widget.vcn.prosesQrCardless(
          kodeQr: kode,
          nominal: nominal,
        );
      }
      if (_pesan.toLowerCase().contains('berhasil')) _nominalController.clear();
    });
  }

  void _aksiGantiPin() {
    final String hasil = widget.akun.rekening.gantiPin(
      _pinLamaController.text,
      _pinBaruController.text,
    );
    setState(() {
      _pesan = hasil;
      if (hasil.toLowerCase().contains('berhasil')) {
        _pinLamaController.clear();
        _pinBaruController.clear();
      }
    });
  }

  void _aksiCekSaldoLog() {
    final Transaksi trx = widget.akun.rekening.cekSaldo();
    setState(() {
      _pesan =
          '${trx.keterangan}: Rp ${Rekening.formatRupiah(trx.saldoSesudah)} (${trx.kodeRef}).';
    });
  }

  void _keluar() {
    widget.vcn.logout();
    Navigator.pop(context);
  }

  Widget _tombolPindahFitur({
    required _MenuVcnPengguna target,
    required IconData ikon,
    required String label,
  }) {
    final bool aktif = _menu == target;
    return Material(
      color: aktif ? _PaletPastelPink.tombolDalam : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: aktif ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _menu = target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: aktif ? Colors.white : _PaletPastelPink.borderPink,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ikon,
                size: 17,
                color: aktif ? Colors.white : _PaletPastelPink.teksGelap,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: aktif ? Colors.white : _PaletPastelPink.teksGelap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Rekening rek = widget.akun.rekening;

    return Scaffold(
      body: _LatarGerakLucu(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.vcn.namaBank} mobile',
                          style: const TextStyle(
                            color: _PaletPastelPink.teksGelap,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _isiDataUjiLkpd,
                              icon: const Icon(Icons.bolt_outlined,
                                  color: _PaletPastelPink.teksGelap, size: 18),
                              label: const Text(
                                'Isi Uji',
                                style: TextStyle(
                                    color: _PaletPastelPink.teksGelap,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _keluar,
                              icon: const Icon(Icons.logout,
                                  color: _PaletPastelPink.teksGelap, size: 18),
                              label: const Text(
                                'Keluar',
                                style: TextStyle(
                                    color: _PaletPastelPink.teksGelap,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _PaletPastelPink.permukaanKartu
                            .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18883C5E),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama: ${widget.akun.namaPengguna}',
                                style: const TextStyle(
                                  color: _PaletPastelPink.teksGelap,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'No. Rekening: ${rek.nomorRekening}',
                                style: const TextStyle(
                                  color: _PaletPastelPink.teksSedang,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Saldo Aktif',
                                style: TextStyle(
                                    color: _PaletPastelPink.teksSedang,
                                    fontSize: 12),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  _tampilkanSaldo
                                      ? 'Rp ${Rekening.formatRupiah(rek.saldo)}'
                                      : 'Rp ••••••',
                                  key: ValueKey(_tampilkanSaldo
                                      ? rek.saldo.round()
                                      : -1),
                                  style: const TextStyle(
                                    color: _PaletPastelPink.teksGelap,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Catat Cek Saldo',
                                onPressed: _aksiCekSaldoLog,
                                icon: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: _PaletPastelPink.teksGelap,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() =>
                                      _tampilkanSaldo = !_tampilkanSaldo);
                                },
                                icon: Icon(
                                  _tampilkanSaldo
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _PaletPastelPink.teksGelap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        _pesan,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _PaletPastelPink.teksGelap,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pilih Fitur Transaksi:',
                      style: TextStyle(
                        color: _PaletPastelPink.teksGelap,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tombolPindahFitur(
                          target: _MenuVcnPengguna.transfer,
                          ikon: Icons.send_rounded,
                          label: 'Kirim / Transfer',
                        ),
                        _tombolPindahFitur(
                          target: _MenuVcnPengguna.tarik,
                          ikon: Icons.atm_rounded,
                          label: 'Tarik Tunai',
                        ),
                        _tombolPindahFitur(
                          target: _MenuVcnPengguna.setor,
                          ikon: Icons.savings_rounded,
                          label: 'Setor Tunai',
                        ),
                        _tombolPindahFitur(
                          target: _MenuVcnPengguna.qris,
                          ikon: Icons.qr_code_2_rounded,
                          label: 'QRIS & Barcode',
                        ),
                        _tombolPindahFitur(
                          target: _MenuVcnPengguna.gantiPin,
                          ikon: Icons.lock_reset_rounded,
                          label: 'Ganti PIN',
                        ),
                        _tombolPindahFitur(
                          target: _MenuVcnPengguna.mutasi,
                          ikon: Icons.receipt_long_rounded,
                          label: 'Mutasi',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _bangunFormPengguna(rek),
                    const SizedBox(height: 14),
                    _TombolNextLucu(
                      label: 'Next • Pindah ke Fitur Berikutnya',
                      sekunder: true,
                      onTap: _lanjutMenuBerikutnya,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bangunFormPengguna(Rekening rek) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _PaletPastelPink.permukaanKartu.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16883C5E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: _transisiKontenHalus(
        _isiFormPengguna(rek),
        key: ValueKey('${_menu.name}_$_modeQr'),
      ),
    );
  }

  Widget _isiFormPengguna(Rekening rek) {
    switch (_menu) {
      case _MenuVcnPengguna.transfer:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Kirim / Transfer Antar Rekening',
                style: TextStyle(
                    color: _PaletPastelPink.teksGelap,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: _tujuanController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(hintText: 'Nomor Rekening Tujuan'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Nominal', prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _aksiTransfer,
              style: FilledButton.styleFrom(
                backgroundColor: _PaletPastelPink.tombolDalam,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Kirim Transfer',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );

      case _MenuVcnPengguna.tarik:
      case _MenuVcnPengguna.setor:
        final bool isTarik = _menu == _MenuVcnPengguna.tarik;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isTarik ? 'Tarik Tunai' : 'Setor Tunai',
                style: const TextStyle(
                    color: _PaletPastelPink.teksGelap,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Nominal', prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: isTarik ? _aksiTarik : _aksiSetor,
              style: FilledButton.styleFrom(
                backgroundColor: _PaletPastelPink.tombolDalam,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isTarik ? 'Proses Tarik Tunai' : 'Proses Setor Tunai',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );

      case _MenuVcnPengguna.qris:
        final String kodeTampil = _kodeQrAktifController.text.trim().isEmpty
            ? rek.kodeQrSetor
            : _kodeQrAktifController.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QRIS & Barcode Rekening',
                  style: TextStyle(
                    color: _PaletPastelPink.teksGelap,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _bukaScannerSimulasi,
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Scan QR'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in [
                  ('SETOR', 'QR Setor'),
                  ('TARIK', 'QR Tarik'),
                  ('TRANSFER', 'QR Transfer'),
                ])
                  ChoiceChip(
                    selected: _modeQr == m.$1,
                    selectedColor: _PaletPastelPink.tombolDalam,
                    backgroundColor: Colors.white,
                    label: Text(
                      m.$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _modeQr == m.$1
                            ? Colors.white
                            : _PaletPastelPink.teksGelap,
                      ),
                    ),
                    onSelected: (_) => _pilihModeQr(m.$1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  _KanvasQrPaket(dataKode: kodeTampil, ukuran: 176),
                  const SizedBox(height: 8),
                  _KanvasBarcode(dataKode: kodeTampil),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kodeQrAktifController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Kode QR / Barcode (mis. VCN:5501001:SETOR)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Nominal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final int n in [50000, 100000, 200000])
                  ActionChip(
                    backgroundColor: Colors.white,
                    label: Text(
                      'Rp ${Rekening.formatRupiah(n.toDouble())}',
                      style: const TextStyle(
                        color: _PaletPastelPink.teksGelap,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _nominalController.text = n.toString());
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _aksiProsesQr,
              style: FilledButton.styleFrom(
                backgroundColor: _PaletPastelPink.tombolDalam,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _modeQr == 'TRANSFER'
                    ? 'Proses Transfer QRIS'
                    : 'Proses QRIS $_modeQr',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );

      case _MenuVcnPengguna.gantiPin:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ganti PIN Bebas',
                style: TextStyle(
                    color: _PaletPastelPink.teksGelap,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: _pinLamaController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'PIN Lama'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pinBaruController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'PIN Baru Bebas'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _aksiGantiPin,
              style: FilledButton.styleFrom(
                backgroundColor: _PaletPastelPink.tombolDalam,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan PIN',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );

      case _MenuVcnPengguna.mutasi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mutasi Transaksi',
                style: TextStyle(
                    color: _PaletPastelPink.teksGelap,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (rek.riwayat.isEmpty)
              const Text('Belum ada transaksi.',
                  style: TextStyle(color: _PaletPastelPink.teksSedang))
            else
              ...rek.riwayat.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${t.jenis} [${t.status}] • Rp ${Rekening.formatRupiah(t.nominal)}\n${t.keterangan} • Saldo Rp ${Rekening.formatRupiah(t.saldoSesudah)}',
                    style: const TextStyle(
                        color: _PaletPastelPink.teksGelap, fontSize: 12),
                  ),
                ),
              ),
          ],
        );
    }
  }
}