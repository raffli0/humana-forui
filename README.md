# Humana Aplikasi Absensi Berbasis Mobile

Humana adalah aplikasi absensi karyawan berbasis Flutter yang dikembangkan untuk mempermudah proses pencatatan kehadiran secara digital. Aplikasi ini memanfaatkan teknologi lokasi (geofencing) dan verifikasi wajah (face liveness detection) untuk meningkatkan keamanan serta keakuratan data absensi.

Aplikasi ini dibuat sebagai proyek pengembangan aplikasi mobile dengan tujuan menerapkan konsep autentikasi, manajemen data, serta integrasi teknologi biometrik dan lokasi.

## Tujuan Pengembangan

Tujuan dari pengembangan aplikasi Humana adalah:
1. Meningkatkan akurasi pencatatan kehadiran karyawan.
2. Mengurangi potensi kecurangan dalam proses absensi.
3. Mempermudah admin dalam memantau kehadiran dan jam kerja.
4. Menerapkan pemanfaatan teknologi mobile, lokasi, dan biometrik.

## Fitur Aplikasi

### Fitur Karyawan
- Check-in berbasis lokasi (geofencing).
- Verifikasi wajah menggunakan face liveness detection.
- Pengambilan foto selfie sebagai bukti absensi.
- Manajemen waktu istirahat.
- Pengajuan cuti dan pemantauan status cuti.
- Riwayat absensi dan jam kerja harian.

### Fitur Admin
- Dashboard absensi karyawan secara real-time.
- Log absensi lengkap (waktu, lokasi, dan foto).
- Manajemen data karyawan dan peran pengguna.
- Pengaturan lokasi kantor dan radius absensi.
- Manajemen jadwal dan shift kerja.

## Tech Stack yang Digunakan
- Framework: Flutter  
- Backend & Database: Firebase  
  - Firebase Authentication(email & password) 
  - Firebase Firestore 
- State Management: Bloc / Cubit  
- Peta dan Lokasi:  
  - flutter_map  
  - OpenStreetMap  
  - CartoDB  
- Face Detection: Google ML Kit  
- UI: Komponen kustom menggunakan forui  
- Integrasi API: Upload foto ke API kustom (PHP) dengan fallback ke Firebase Storage  

## Showcase Aplikasi

| Login | Register | Splash | Onboarding |
|:---:|:---:|:---:|:---:|
| <img src="docs/login.jpeg" alt="Login" width="200"/> | <img src="docs/register.jpeg" alt="Register" width="200"/> | <img src="docs/splash.jpeg" alt="Splash" width="200"/> | <img src="docs/onboarding.jpeg" alt="Onboarding" width="200"/> |

| Home Karyawan | Attendance | Leaves | Attendance History | Profile |
|:---:|:---:|:---:|:---:|:---:|
| <img src="docs/home_karyawan.jpeg" alt="Home" width="200"/> | <img src="docs/attend_karyawan.jpeg" alt="Attendance" width="200"/> | <img src="docs/leave_req_karyawan.jpeg" alt="Leaves" width="200"/> | <img src="docs/history.jpeg" alt="Attendance History" width="200"/> | <img src="docs/profile.jpeg" alt="Profile" width="200"/> |

| Home Admin | Monitor | Leaves | Users Management | Settings | Set Office Location | 
|:---:|:---:|:---:|:---:|:---:|:---:|
| <img src="docs/admin/home.jpeg" alt="Home" width="200"/> | <img src="docs/admin/attend_history.jpeg" alt="Monitor" width="200"/> | <img src="docs/admin/manage_leave.jpeg" alt="Leaves" width="200"/> | <img src="docs/admin/users_management.jpeg" alt="Users Management" width="200"/> | <img src="docs/admin/settings.jpeg" alt="Settings" width="200"/> | <img src="docs/admin/set_office_loc.jpeg" alt="Set Office Location" width="200"/> |



### Daftar Halaman Aplikasi Shift
A. Halaman Umum
1. Splash Screen
    - Halaman pembuka aplikasi yang ditampilkan saat aplikasi pertama kali dijalankan.
2. Onboarding Screen
    - Halaman pengenalan aplikasi yang berisi informasi singkat mengenai fitur dan fungsi utama aplikasi.
3. Halaman Login
    - Halaman untuk autentikasi pengguna menggunakan akun yang terdaftar.
4. Halaman Register
    - Halaman untuk melakukan pendaftaran pengguna sebagai admin atau karyawan.
B. Halaman Karyawan
5. Halaman Home (Karyawan)
    - Menampilkan informasi utama karyawan seperti status kehadiran hari ini, jam kerja, dan menu navigasi ke fitur lainnya.
6. Halaman Attendance (Karyawan)
    - Checkin untuk melakukan absensi masuk dengan validasi lokasi (geofencing) dan pengambilan foto sebagai bukti kehadiran.
    - Checkout untuk melakukan absensi pulang yang mencatat waktu dan lokasi pengguna.
    - Break untuk memulai dan mengakhiri waktu istirahat karyawan dengan pencatatan durasi otomatis.
7. Halaman Request (Karyawan)
    - Halam untuk melakukan pengajuan cuti(liburan, sakit, dsb) serta melihat status pengajuan cuti.
8. Halaman History Absensi (Karyawan)
    - Menampilkan detail absensi seluruh karyawan, termasuk waktu, lokasi pada peta, dan foto bukti.
9. Halaman Profil Pengguna (karyawan)
    - Menampilkan informasi profil pengguna dan pengaturan akun.
10. Halaman Home (admin)
    - Menampilkan ringkasan data kehadiran seluruh karyawan secara keseluruhan.
11. Halaman Monitor (admin)
    - Menampilkan history data kehadiran seluruh karyawan.
12. Halaman Leaves (admin)
    - Halaman untuk mengelola pengajuan cuti seluruh karyawan.
13. Halaman Users Management (admin)
    - Halaman untuk mengelola data karyawan, termasuk penambahan, pengubahan, dan penghapusan data.
14. Halaman Settings (admin)
    - Untuk mengelola jam kerja pada seluruh karyawan.
    - Untuk menentukan lokasi kantor dan radius kehadiran menggunakan peta.
15. Halaman Profil Pengguna (admin)
    - Menampilkan informasi profil pengguna dan pengaturan akun.

## (Getting Started)

### Syarat
- Flutter SDK (versi stabil terbaru)
- Setup Proyek Firebase (google-services.json)

### Instalasi

1. **Clone repositori**
   ```bash
   git clone https://github.com/raffli0/shift-app.git
   cd shift
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```
### Kesimpulan
Aplikasi Shift merupakan implementasi sistem absensi digital yang mengintegrasikan teknologi mobile, lokasi, dan biometrik. Dengan adanya fitur geofencing dan face liveness detection, aplikasi ini diharapkan dapat meningkatkan keamanan serta keakuratan data kehadiran dibandingkan dengan sistem absensi konvensional.
