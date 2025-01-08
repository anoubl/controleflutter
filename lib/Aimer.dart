class Aimer {
  String id;
  String title;
  String year;
  String poster;

  Aimer({required this.id, required this.title, required this.year, required this.poster});

  // Convert a Firestore document to an Aimer object
  factory Aimer.fromFirestore(Map<String, dynamic> json, String id) {
    return Aimer(
      id: id,
      title: json['title'] ?? '',
      year: json['year'] ?? '',
      poster: json['poster'] ?? '',
    );
  }

  // Convert an Aimer object to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'year': year,
      'poster': poster,
    };
  }
}
