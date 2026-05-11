class Movie {
  final int id;
  final String title;
  final String posterPath;
  final double voteAverage;
  final String dominantEmotion;

  Movie({required this.id, required this.title, required this.posterPath, required this.voteAverage, required this.dominantEmotion});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      // Backend'den gelen poster_path tam URL olmayabilir, TMDB formatına uygun hale getiriyoruz
      posterPath: json['poster_path'] != null 
          ? "https://image.tmdb.org/t/p/w500${json['poster_path']}" 
          : "https://via.placeholder.com/500x750?text=No+Image",
      voteAverage: (json['vote_average'] as num).toDouble(),
      dominantEmotion: json['dominant_emotion'] ?? "Genel",
    );
  }
}