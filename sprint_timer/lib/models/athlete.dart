class Athlete {
  final String id;
  String name;
  String? bibNumber;
  String? category; // e.g. U18, Senior, etc.

  Athlete({
    required this.id,
    required this.name,
    this.bibNumber,
    this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bib_number': bibNumber,
    'category': category,
  };

  factory Athlete.fromMap(Map<String, dynamic> map) => Athlete(
    id: map['id'],
    name: map['name'],
    bibNumber: map['bib_number'],
    category: map['category'],
  );

  @override
  String toString() => bibNumber != null ? '#$bibNumber $name' : name;
}
