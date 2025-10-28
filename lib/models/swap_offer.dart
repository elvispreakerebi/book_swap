enum SwapOfferState { pending, accepted, completed, cancelled }

class SwapOffer {
  final String offerId;
  final String listingId;
  final String fromUserId;
  final String toUserId;
  final SwapOfferState state;
  final DateTime createdAt;

  SwapOffer({
    required this.offerId,
    required this.listingId,
    required this.fromUserId,
    required this.toUserId,
    required this.state,
    required this.createdAt,
  });

  factory SwapOffer.fromJson(Map<String, dynamic> json) {
    return SwapOffer(
      offerId: json['offerId'],
      listingId: json['listingId'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      state: SwapOfferState.values.firstWhere(
        (e) => e.name == (json['state'] ?? 'pending'),
        orElse: () => SwapOfferState.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'offerId': offerId,
    'listingId': listingId,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'state': state.name,
    'createdAt': createdAt.toIso8601String(),
  };

  SwapOffer copyWith({
    String? offerId,
    String? listingId,
    String? fromUserId,
    String? toUserId,
    SwapOfferState? state,
    DateTime? createdAt,
  }) {
    return SwapOffer(
      offerId: offerId ?? this.offerId,
      listingId: listingId ?? this.listingId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
