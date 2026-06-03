import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';

class PersonScreen extends StatefulWidget {
  final int personId;
  final String name;

  const PersonScreen({super.key, required this.personId, required this.name});

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonProvider>().load(widget.personId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonProvider>(
      builder: (_, provider, __) {
        if (provider.loading) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.name)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.error != null || provider.person == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.name)),
            body: Center(child: Text(provider.error ?? 'Error', style: TextStyle(color: Colors.grey.shade400))),
          );
        }

        final p = provider.person!;
        final profilePath = p['profile_path'] as String?;
        final name = p['name'] as String? ?? widget.name;
        final biography = p['biography'] as String? ?? '';
        final birthday = p['birthday'] as String?;
        final placeOfBirth = p['place_of_birth'] as String?;
        final department = p['known_for_department'] as String?;
        final credits = (p['combined_credits']?['cast'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .where((c) => c['poster_path'] != null)
            .toList()
          ..sort((a, b) {
            final dateA = (a['release_date'] ?? a['first_air_date'] ?? '') as String;
            final dateB = (b['release_date'] ?? b['first_air_date'] ?? '') as String;
            return dateB.compareTo(dateA);
          });

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: profilePath != null ? 300 : 0,
                flexibleSpace: profilePath != null
                    ? FlexibleSpaceBar(
                        background: CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w500$profilePath',
                          fit: BoxFit.cover,
                          color: Colors.black38,
                          colorBlendMode: BlendMode.darken,
                        ),
                      )
                    : null,
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profilePath != null) ...[
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w185$profilePath',
                                width: 90,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (department != null) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5)),
                                      ),
                                      child: Text(department, style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
                                    ),
                                  ],
                                  if (birthday != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.cake_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(_formatDate(birthday), style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                        Text(_age(birthday), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                  if (placeOfBirth != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(placeOfBirth, style: TextStyle(color: Colors.grey.shade400, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (biography.isNotEmpty) ...[
                        const Text('Biografía', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: _bioExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: Text(biography, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade300, height: 1.5)),
                          secondChild: Text(biography, style: TextStyle(color: Colors.grey.shade300, height: 1.5)),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _bioExpanded = !_bioExpanded),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text(_bioExpanded ? 'Ver menos' : 'Ver más', style: const TextStyle(color: Color(0xFF6C63FF))),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (credits.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Filmografía (${credits.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              if (credits.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final credit = credits[i];
                        final tmdbId = credit['id'] as int?;
                        final mediaType = credit['media_type'] as String? ?? 'movie';
                        final title = credit['title'] as String? ?? credit['name'] as String? ?? '';
                        final posterPath = credit['poster_path'] as String?;
                        final date = (credit['release_date'] ?? credit['first_air_date'] ?? '') as String;
                        final year = date.length >= 4 ? date.substring(0, 4) : '';

                        return GestureDetector(
                          onTap: tmdbId != null
                              ? () => context.push('/detail/$tmdbId?type=$mediaType&title=${Uri.encodeComponent(title)}')
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: 'https://image.tmdb.org/t/p/w342$posterPath',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(color: const Color(0xFF2C2C2E)),
                                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF2C2C2E), child: const Icon(Icons.movie, color: Colors.grey)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                              if (year.isNotEmpty)
                                Text(year, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                      childCount: credits.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length < 3) return date;
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${parts[2]} ${months[month - 1]}. ${parts[0]}';
  }

  String _age(String birthday) {
    final birth = DateTime.tryParse(birthday);
    if (birth == null) return '';
    final age = DateTime.now().difference(birth).inDays ~/ 365;
    return '  ($age años)';
  }
}
