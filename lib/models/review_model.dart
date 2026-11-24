class ReviewModel {
  final int? id;
  final int orderId;
  final int gearId;
  final String userName;
  final double rating;
  final String comment;
  final String? ownerReply;
  final String createdAt;

  ReviewModel({
    this.id,
    required this.orderId,
    required this.gearId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.ownerReply,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'gearId': gearId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'ownerReply': ownerReply,
      'createdAt': createdAt,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      orderId: map['orderId'],
      gearId: map['gearId'],
      userName: map['userName'],
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'],
      ownerReply: map['ownerReply'],
      createdAt: map['createdAt'],
    );
  }
}
