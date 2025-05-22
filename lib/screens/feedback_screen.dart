import 'package:flutter/material.dart';
import 'package:toko_game/utils/constants.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan & Pesan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?q=80&w=1470&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black26,
                    BlendMode.darken,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Kesan & Pesan\nTeknologi Pemrograman Mobile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Author section
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Febrian Chrisna Ardianto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semester Genap 2024/2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Content
            const Text(
              'Perjalanan yang Berharga',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Selama mengikuti mata kuliah Teknologi Pemrograman Mobile, saya merasa tertantang dan terkadang kelelahan karena banyaknya tugas yang harus diselesaikan. Namun, di balik itu semua terdapat pembelajaran yang sangat berharga.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Meski beban tugas terkadang terasa berat, tantangan tersebut justru mendorong saya untuk terus berkembang dan memperdalam pemahaman tentang pengembangan aplikasi mobile. Proses ini melatih ketahanan mental dan kemampuan problem-solving saya.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Keahlian dan pengetahuan yang saya peroleh selama perkuliahan ini sangat relevan dengan dunia industri saat ini, dan saya bersyukur telah mendapatkan kesempatan untuk mengembangkan aplikasi ini sebagai proyek akhir.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Harapan Ke Depan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Saya berharap semua usaha dan perjuangan yang telah dilakukan selama satu semester ini membuahkan hasil yang baik. Semoga ilmu yang telah dipelajari dapat bermanfaat untuk karir di masa depan.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Terima kasih kepada dosen pengampu yang telah membimbing dan memberikan pengetahuan yang berharga. Semoga ke depannya mata kuliah ini terus berkembang dan dapat memberikan lebih banyak manfaat untuk mahasiswa selanjutnya.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 32),

            // Quote
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.format_quote,
                    size: 32,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kesuksesan tidak datang dari apa yang diberikan oleh orang lain, melainkan dari kerja keras dan pembelajaran yang konsisten.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
