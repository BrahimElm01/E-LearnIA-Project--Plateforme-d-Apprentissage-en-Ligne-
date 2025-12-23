class Review {
  final int id;
  final String studentName;
  final int rating;
  final String comment;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime createdAt;

  Review({
    required this.id,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      studentName: json['studentName'] as String? ?? 'Utilisateur',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
}











