import 'package:flutter/material.dart';
import 'poster_image.dart';

class MediaCard extends StatelessWidget {
  final String? posterUrl;
  final String title;
  final String? year;
  final double? rating;
  final double? userRating;
  final VoidCallback? onTap;
  final double width;

  const MediaCard({
    super.key,
    required this.posterUrl,
    required this.title,
    this.year,
    this.rating,
    this.userRating,
    this.onTap,
    this.width = 120,
  });

  Widget _ratingBadge() => Positioned(
        top: 6,
        left: 6,
        child: _badge(rating!.toStringAsFixed(1), const Color(0xFFFFC107)),
      );

  Widget _userRatingBadge() => Positioned(
        bottom: 6,
        left: 6,
        child: _badge(userRating!.toStringAsFixed(1), const Color(0xFF6C63FF)),
      );

  Widget _badge(String value, Color starColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: starColor, size: 12),
            const SizedBox(width: 2),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _textSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (year != null && year!.isNotEmpty)
            Text(
              year!,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasFixedWidth = constraints.maxWidth.isFinite;
          final hasFixedHeight = constraints.maxHeight.isFinite && constraints.maxHeight < 9999;
          final w = hasFixedWidth ? constraints.maxWidth : width;

          // Grid mode: both dimensions bounded — use Expanded for image, natural text below
          if (hasFixedWidth && hasFixedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      PosterImage(
                        url: posterUrl,
                        width: w,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      if (rating != null && rating! > 0) _ratingBadge(),
                      if (userRating != null) _userRatingBadge(),
                    ],
                  ),
                ),
                _textSection(),
              ],
            );
          }

          // List mode: only width bounded (horizontal scroll) — fixed image ratio
          return SizedBox(
            width: w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    PosterImage(
                      url: posterUrl,
                      width: w,
                      height: w * 1.5,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    if (rating != null && rating! > 0) _ratingBadge(),
                    if (userRating != null) _userRatingBadge(),
                  ],
                ),
                _textSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}
