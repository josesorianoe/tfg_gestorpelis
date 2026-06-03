import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../../../shared/widgets/media_card.dart';

class PopularScreen extends StatelessWidget {
  const PopularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.read<HomeProvider>().discover;

    return Scaffold(
      appBar: AppBar(title: const Text('Populares ahora')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return MediaCard(
            posterUrl: item.fullPosterUrl,
            title: item.title,
            year: item.year,
            rating: item.voteAverage,
            onTap: () => context.push(
              '/detail/${item.tmdbId}?type=${item.mediaType}&title=${Uri.encodeComponent(item.title)}',
            ),
          );
        },
      ),
    );
  }
}
