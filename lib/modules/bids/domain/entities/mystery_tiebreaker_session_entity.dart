/// Represents an active or completed mystery auction tiebreaker session
class TiebreakerSessionEntity {
  final String id;
  final String auctionId;
  final TiebreakerType type;
  final TiebreakerStatus status;
  final double tiedAmount;
  final int initialTiedCount;
  final int readyCount;
  final List<ReadyParticipant> readyAliases;
  final DateTime readyDeadline;
  final bool isReady;
  final bool isParticipant;
  // RPS
  final int rpsCurrentRound;
  final String? myRpsChoice;
  final bool opponentSubmitted;
  final bool bothSubmitted;
  final Map<String, String>? rpsChoicesRevealed;
  final List<RpsRoundEntity> rpsRounds;
  // Wheel
  final String? wheelSeed;
  final int? wheelWinnerIndex;
  // Result
  final String? winnerId;
  final String myAlias;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TiebreakerSessionEntity({
    required this.id,
    required this.auctionId,
    required this.type,
    required this.status,
    required this.tiedAmount,
    required this.initialTiedCount,
    required this.readyCount,
    required this.readyAliases,
    required this.readyDeadline,
    required this.isReady,
    required this.isParticipant,
    required this.rpsCurrentRound,
    this.myRpsChoice,
    required this.opponentSubmitted,
    required this.bothSubmitted,
    this.rpsChoicesRevealed,
    required this.rpsRounds,
    this.wheelSeed,
    this.wheelWinnerIndex,
    this.winnerId,
    required this.myAlias,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDeadlinePassed => DateTime.now().isAfter(readyDeadline);

  Duration get deadlineRemaining {
    final diff = readyDeadline.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory TiebreakerSessionEntity.fromJson(Map<String, dynamic> json) {
    // Parse ready aliases
    final aliasesRaw = json['ready_aliases'];
    List<ReadyParticipant> readyAliases = [];
    if (aliasesRaw is List) {
      for (final item in aliasesRaw) {
        if (item is List) {
          for (final entry in item) {
            if (entry is Map<String, dynamic>) {
              readyAliases.add(ReadyParticipant.fromJson(entry));
            }
          }
        } else if (item is Map<String, dynamic>) {
          readyAliases.add(ReadyParticipant.fromJson(item));
        }
      }
    }

    // Parse RPS rounds
    final roundsRaw = json['rps_rounds'];
    List<RpsRoundEntity> rpsRounds = [];
    if (roundsRaw is List) {
      rpsRounds = roundsRaw
          .whereType<Map<String, dynamic>>()
          .map(RpsRoundEntity.fromJson)
          .toList();
    }

    // Parse revealed choices
    Map<String, String>? choicesRevealed;
    final choicesRaw = json['rps_choices_revealed'];
    if (choicesRaw is Map) {
      choicesRevealed = Map<String, String>.from(
        choicesRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );
    }

    return TiebreakerSessionEntity(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      type: TiebreakerType.fromString(
        json['tiebreaker_type'] as String? ?? 'rps',
      ),
      status: TiebreakerStatus.fromString(
        json['status'] as String? ?? 'waiting_ready',
      ),
      tiedAmount: (json['tied_amount'] as num?)?.toDouble() ?? 0,
      initialTiedCount: json['initial_tied_count'] as int? ?? 2,
      readyCount: json['ready_count'] as int? ?? 0,
      readyAliases: readyAliases,
      readyDeadline: DateTime.parse(json['ready_deadline'] as String),
      isReady: json['is_ready'] as bool? ?? false,
      isParticipant: json['is_participant'] as bool? ?? false,
      rpsCurrentRound: json['rps_current_round'] as int? ?? 0,
      myRpsChoice: json['my_rps_choice'] as String?,
      opponentSubmitted: json['opponent_submitted'] as bool? ?? false,
      bothSubmitted: json['both_submitted'] as bool? ?? false,
      rpsChoicesRevealed: choicesRevealed,
      rpsRounds: rpsRounds,
      wheelSeed: json['wheel_seed'] as String?,
      wheelWinnerIndex: json['wheel_winner_index'] as int?,
      winnerId: json['winner_id'] as String?,
      myAlias: json['my_alias'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ReadyParticipant {
  final String userId;
  final String alias;

  const ReadyParticipant({required this.userId, required this.alias});

  factory ReadyParticipant.fromJson(Map<String, dynamic> json) =>
      ReadyParticipant(
        userId: json['user_id'] as String,
        alias: json['alias'] as String? ?? 'Unknown',
      );
}

class RpsRoundEntity {
  final int round;
  final String p1Id;
  final String p1Choice;
  final String p2Id;
  final String p2Choice;
  final String result; // 'tie' or 'winner'
  final String? winnerId;

  const RpsRoundEntity({
    required this.round,
    required this.p1Id,
    required this.p1Choice,
    required this.p2Id,
    required this.p2Choice,
    required this.result,
    this.winnerId,
  });

  factory RpsRoundEntity.fromJson(Map<String, dynamic> json) => RpsRoundEntity(
    round: json['round'] as int? ?? 0,
    p1Id: json['p1_id'] as String,
    p1Choice: json['p1_choice'] as String,
    p2Id: json['p2_id'] as String,
    p2Choice: json['p2_choice'] as String,
    result: json['result'] as String? ?? 'tie',
    winnerId: json['winner_id'] as String?,
  );
}

enum TiebreakerType {
  rps,
  wheel;

  static TiebreakerType fromString(String s) =>
      s == 'wheel' ? TiebreakerType.wheel : TiebreakerType.rps;
}

enum TiebreakerStatus {
  waitingReady,
  rpsInProgress,
  wheelInProgress,
  completed,
  dqAll;

  static TiebreakerStatus fromString(String s) => switch (s) {
    'rps_in_progress' => TiebreakerStatus.rpsInProgress,
    'wheel_in_progress' => TiebreakerStatus.wheelInProgress,
    'completed' => TiebreakerStatus.completed,
    'dq_all' => TiebreakerStatus.dqAll,
    _ => TiebreakerStatus.waitingReady,
  };
}

/// Minimal participant info for bid history tab (active mystery)
class MysteryParticipantEntity {
  final String bidderId;
  final String auctionId;
  final DateTime submittedAt;

  const MysteryParticipantEntity({
    required this.bidderId,
    required this.auctionId,
    required this.submittedAt,
  });
}
