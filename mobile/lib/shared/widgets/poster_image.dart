import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

class PosterImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const PosterImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIcon = Icons.movie_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (url == null || url!.isEmpty) {
      return _placeholder(radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _shimmer(),
        errorWidget: (_, url, err) {
          debugPrint('PosterImage ERROR: $url — $err');
          return _placeholder(BorderRadius.zero);
        },
      ),
    );
  }

  Widget _shimmer() => Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      );

  Widget _placeholder(BorderRadius radius) => Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: radius,
        ),
        child: Icon(placeholderIcon, color: Colors.grey, size: 32),
      );
}
