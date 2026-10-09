import 'dart:convert';

class Tier {
  const Tier({
    required this.id,
    required this.label,
    required this.model,
    required this.url,
    required this.sha256,
    required this.maxRamMb,
    required this.sizeMb,
    required this.chunkChars,
    required this.questionsPerChunk,
    required this.cardsPerChunk,
  });

  factory Tier.fromJson(Map<String, dynamic> j) => Tier(
        id: j['id'] as String,
        label: j['label'] as String,
        model: j['model'] as String,
        url: j['url'] as String,
        sha256: j['sha256'] as String,
        maxRamMb: j['maxRamMb'] as int?,
        sizeMb: j['sizeMb'] as int,
        chunkChars: j['chunkChars'] as int,
        questionsPerChunk: j['questionsPerChunk'] as int,
        cardsPerChunk: j['cardsPerChunk'] as int,
      );

  final String id, label, model, url, sha256;
  final int? maxRamMb; // exclusive upper bound; null = no limit
  final int sizeMb, chunkChars, questionsPerChunk, cardsPerChunk;
}

class TierTable {
  TierTable.fromJson(String json)
      : tiers = [
          for (final t in (jsonDecode(json)['tiers'] as List))
            Tier.fromJson(t as Map<String, dynamic>)
        ];

  /// Ascending by capability.
  final List<Tier> tiers;

  Tier pick(int ramMb) => tiers.firstWhere(
        (t) => t.maxRamMb == null || ramMb < t.maxRamMb!,
        orElse: () => tiers.last,
      );

  Tier byId(String id) => tiers.firstWhere((t) => t.id == id);

  Tier? lower(Tier t) {
    final i = tiers.indexWhere((x) => x.id == t.id);
    return i > 0 ? tiers[i - 1] : null;
  }

  bool fitsStorage(Tier t, int freeMb) => freeMb >= (t.sizeMb * 1.25).ceil();
}
