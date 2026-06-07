class Movie {
  final int id;
  final String title;
  final String originalTitle;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final String releaseDate;
  final String originalLanguage;
  final double voteAverage;
  final int voteCount;
  final double popularity;

  Movie({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.originalLanguage,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) => (val is num) ? val.toDouble() : 0.0;
    int toInt(dynamic val) => (val is num) ? val.toInt() : 0;

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? "Bilinmiyor",
      originalTitle: json['original_title'] ?? "",
      overview: json['overview'] ?? "Özet bulunamadı.",
      posterPath: json['poster_path'] ?? "",
      backdropPath: json['backdrop_path'] ?? "",
      releaseDate: json['release_date'] ?? (json['release_year']?.toString() ?? ""),
      originalLanguage: json['original_language'] ?? "en",
      voteAverage: toDouble(json['vote_average']),
      voteCount: toInt(json['vote_count']),
      popularity: toDouble(json['popularity']),
    );
  }
}