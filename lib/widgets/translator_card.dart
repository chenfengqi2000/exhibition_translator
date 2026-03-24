import 'package:flutter/material.dart';
import '../models/translator.dart';

class TranslatorCard extends StatelessWidget {
  final Translator translator;
  final VoidCallback? onTap;
  /// null 表示不显示收藏按钮；非 null 表示雇主身份，isFavorited 决定图标状态
  final bool? isFavorited;
  final VoidCallback? onFavoriteToggle;

  const TranslatorCard({
    super.key,
    required this.translator,
    this.onTap,
    this.isFavorited,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = translator.avatar.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2A4A).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: hasAvatar ? NetworkImage(translator.avatar) : null,
              backgroundColor: const Color(0xFFDBEAFE),
              child: !hasAvatar
                  ? Text(
                      translator.name.isNotEmpty ? translator.name[0] : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A6CF7),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        translator.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2A4A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          translator.languageLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF155DFC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    translator.intro.isNotEmpty ? translator.intro : translator.cityLabel,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8F9BB3)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(
                        translator.ratingSummary.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E2A4A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        translator.priceLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6CF7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 收藏按钮：仅当 isFavorited 非 null（雇主身份）时显示
            if (isFavorited != null)
              GestureDetector(
                onTap: onFavoriteToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    isFavorited! ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFavorited! ? const Color(0xFFEF4444) : const Color(0xFF8F9BB3),
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFF8F9BB3)),
          ],
        ),
      ),
    );
  }
}
