/*
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F12), // Koyu arka plan
      appBar: AppBar(title: Text("Kişisel Arşivim"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Buraya fl_chart ile PieChart gelecek (KNN Vizyonu)
            _buildInsightSection(), 
            
            // Raflar (Kütüphane görünümü)
            buildShelf("Neşe Koleksiyonum", joyMovies),
            buildShelf("Hüzünlü Anılar", sadMovies),
          ],
        ),
      ),
    );
  }

  Widget buildShelf(String title, List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(title, style: TextStyle(color: Color(0xFFE0C097), fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) => _buildArchiveCard(movies[index]),
          ),
        ),
        Divider(color: Colors.white10),
      ],
    );
  }
}
*/