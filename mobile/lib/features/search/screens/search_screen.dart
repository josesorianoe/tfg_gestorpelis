import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../../../core/models/person_result.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/poster_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().clear();
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<SearchProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final isPerson = provider.type == 'person';

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: isPerson
                    ? 'Busca actores y directores...'
                    : 'Busca películas o series...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _ctrl.clear();
                          context.read<SearchProvider>().clear();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                if (v.length >= 2) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (_ctrl.text == v) {
                      context.read<SearchProvider>().search(v, reset: true);
                    }
                  });
                } else if (v.isEmpty) {
                  context.read<SearchProvider>().clear();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _TypeChip(label: 'Películas', value: 'movie', selected: provider.type == 'movie'),
                const SizedBox(width: 8),
                _TypeChip(label: 'Series', value: 'tv', selected: provider.type == 'tv'),
                const SizedBox(width: 8),
                _TypeChip(label: 'Personas', value: 'person', selected: provider.type == 'person'),
              ],
            ),
          ),
          Expanded(
            child: _buildResults(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchProvider provider) {
    final isPerson = provider.type == 'person';
    final isEmpty = isPerson ? provider.personResults.isEmpty : provider.results.isEmpty;
    final itemCount = isPerson ? provider.personResults.length : provider.results.length;

    if (provider.loading && isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isEmpty && provider.query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade700),
            const SizedBox(height: 12),
            Text(
              'Sin resultados para "${provider.query}"',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPerson ? Icons.person_search_rounded : Icons.movie_outlined,
              size: 56,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              isPerson
                  ? 'Busca actores y directores'
                  : 'Busca tus películas y series favoritas',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: itemCount + (provider.hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == itemCount) {
          return const Center(child: CircularProgressIndicator());
        }
        if (isPerson) {
          return _PersonCard(person: provider.personResults[i]);
        }
        final item = provider.results[i];
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
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;

  const _TypeChip({required this.label, required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => context.read<SearchProvider>().setType(value),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonResult person;

  const _PersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/person/${person.id}?name=${Uri.encodeComponent(person.name)}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PosterImage(
              url: person.fullProfileUrl,
              width: double.infinity,
              borderRadius: BorderRadius.circular(10),
              placeholderIcon: Icons.person_rounded,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (person.departmentLabel.isNotEmpty)
            Text(
              person.departmentLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
