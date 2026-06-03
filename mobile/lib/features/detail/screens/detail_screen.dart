import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_list.dart';
import '../../../features/home/providers/home_provider.dart';
import '../providers/detail_provider.dart';
import '../providers/season_provider.dart';

class DetailScreen extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final String title;

  const DetailScreen({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<DetailProvider>();
      p.loadDetail(widget.tmdbId, widget.mediaType);
      p.loadMediaStatus(widget.tmdbId, widget.mediaType);
      if (widget.mediaType == 'tv') {
        context.read<SeasonProvider>().loadProgress(widget.tmdbId);
      }
    });
  }

  Future<void> _showSheet(BuildContext context, Widget Function(DetailProvider) sheetBuilder) async {
    final detail = context.read<DetailProvider>();
    await detail.loadUserLists();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: detail,
        child: sheetBuilder(detail),
      ),
    );
  }

  void _showAddToList(BuildContext context) {
    if (widget.mediaType == 'tv') {
      final seasonProv = context.read<SeasonProvider>();
      _showSheet(context, (_) => _TvAddFlowSheet(tmdbId: widget.tmdbId, seasonProvider: seasonProv));
    } else {
      _showSheet(context, (_) => _AddToListSheet(tmdbId: widget.tmdbId, mediaType: widget.mediaType));
    }
  }

  void _showPendingActionSheet(BuildContext context) => _showSheet(
        context,
        (_) => _PendingActionSheet(tmdbId: widget.tmdbId, mediaType: widget.mediaType),
      );

  void _showCurrentListSheet(BuildContext context) => _showSheet(
        context,
        (_) => _CurrentListActionSheet(tmdbId: widget.tmdbId, mediaType: widget.mediaType),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && context.read<DetailProvider>().listChanged) {
          context.read<HomeProvider>().refreshLists();
        }
      },
      child: Scaffold(
      body: Consumer<DetailProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.title)),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.error != null) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.title)),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                    const SizedBox(height: 12),
                    Text(provider.error!, style: TextStyle(color: Colors.grey.shade400)),
                    TextButton(
                      onPressed: () => provider.loadDetail(widget.tmdbId, widget.mediaType),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final d = provider.detail;
          if (d == null) return const SizedBox();

          final title = d['title'] as String? ?? d['name'] as String? ?? '';
          final overview = d['overview'] as String? ?? '';
          final backdropPath = d['backdrop_path'] as String?;
          final posterPath = d['poster_path'] as String?;
          final rating = (d['vote_average'] as num?)?.toDouble() ?? 0.0;
          final releaseDate = d['release_date'] as String? ?? d['first_air_date'] as String? ?? '';
          final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
          final genres = (d['genres'] as List<dynamic>?) ?? [];
          final seriesStatus = widget.mediaType == 'tv' ? d['status'] as String? : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                flexibleSpace: FlexibleSpaceBar(
                  background: backdropPath != null
                      ? CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w780$backdropPath',
                          fit: BoxFit.cover,
                          color: Colors.black38,
                          colorBlendMode: BlendMode.darken,
                        )
                      : Container(color: const Color(0xFF1C1C1E)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (posterPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w342$posterPath',
                                width: 100,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                if (year.isNotEmpty)
                                  Text(year, style: TextStyle(color: Colors.grey.shade400)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    Text(' / 10', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (genres.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: genres.take(3).map((g) {
                                      final name = (g is Map) ? g['name'] as String? ?? '' : g.toString();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2C2C2E),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      );
                                    }).toList(),
                                  ),
                                if (seriesStatus != null) ...[
                                  const SizedBox(height: 6),
                                  _SeriesStatusBadge(status: seriesStatus),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: provider.addingToList ? null : () {
                          if (provider.inNonDefaultList) {
                            _showCurrentListSheet(context);
                          } else if (provider.isOnlyInPending) {
                            _showPendingActionSheet(context);
                          } else {
                            _showAddToList(context);
                          }
                        },
                        icon: provider.addingToList
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(provider.inNonDefaultList || provider.isOnlyInPending
                                ? Icons.swap_horiz_rounded
                                : Icons.playlist_add_rounded),
                        label: Text(
                          provider.inNonDefaultList || provider.isOnlyInPending
                              ? 'En ${provider.currentListName ?? 'lista'}'
                              : 'Añadir a lista',
                        ),
                      ),
                      if (overview.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Sinopsis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(overview, style: TextStyle(color: Colors.grey.shade300, height: 1.5)),
                      ],
                      _CastSection(detail: d),
                      if (widget.mediaType == 'tv') ...[
                        const SizedBox(height: 24),
                        _SeasonsSection(
                          tmdbId: widget.tmdbId,
                          seasons: (d['seasons'] as List<dynamic>?) ?? [],
                        ),
                      ],
                      _ReviewSection(tmdbId: widget.tmdbId, mediaType: widget.mediaType),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ), // Scaffold
    ); // PopScope
  }
}

class _ReviewSection extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  const _ReviewSection({required this.tmdbId, required this.mediaType});

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  final _noteCtrl = TextEditingController();
  double? _rating;
  bool _synced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_synced) {
      final p = context.read<DetailProvider>();
      if (p.inNonDefaultList) {
        _rating = p.userRating;
        _noteCtrl.text = p.userNote;
        _synced = true;
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetailProvider>();

    if (!provider.inNonDefaultList) return const SizedBox();

    if (!_synced) {
      _rating = provider.userRating;
      _noteCtrl.text = provider.userNote;
      _synced = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Mi reseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
            const SizedBox(width: 8),
            Text(
              _rating != null ? _rating!.toStringAsFixed(1) : '—',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(' / 10', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
        Slider(
          value: _rating ?? 0,
          min: 0,
          max: 10,
          divisions: 20,
          activeColor: const Color(0xFF6C63FF),
          inactiveColor: const Color(0xFF2C2C2E),
          onChanged: (v) => setState(() => _rating = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe tu opinión...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.edit_note_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.savingReview
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await provider.saveReview(
                      widget.tmdbId,
                      widget.mediaType,
                      _rating,
                      _noteCtrl.text,
                    );
                    messenger.showSnackBar(SnackBar(
                      content: Text(ok ? 'Reseña guardada' : provider.reviewError ?? 'Error'),
                      backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                    ));
                  },
            child: provider.savingReview
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar reseña'),
          ),
        ),
      ],
    );
  }
}

class _CastSection extends StatelessWidget {
  final Map<String, dynamic> detail;
  const _CastSection({required this.detail});

  Map<String, dynamic>? _findDirector() {
    // Movies: credits.crew with job == Director
    final crew = (detail['credits']?['crew'] as List<dynamic>?);
    if (crew != null) {
      final director = crew.cast<Map<String, dynamic>>().where((m) => m['job'] == 'Director').firstOrNull;
      if (director != null) return director;
    }
    // TV: created_by
    final createdBy = (detail['created_by'] as List<dynamic>?);
    return createdBy?.cast<Map<String, dynamic>>().firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final credits = detail['credits'];
    final cast = (credits?['cast'] as List<dynamic>?)
        ?.take(15)
        .where((m) => m['profile_path'] != null)
        .toList();
    final director = _findDirector();

    if ((cast == null || cast.isEmpty) && director == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Reparto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        if (director != null) ...[
          _PersonCard(
            personId: director['id'] as int?,
            profilePath: director['profile_path'] as String?,
            name: director['name'] as String? ?? '',
            label: 'Dirección',
            labelColor: const Color(0xFF6C63FF),
          ),
          const SizedBox(height: 12),
        ],
        if (cast != null && cast.isNotEmpty)
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final member = cast[i] as Map<String, dynamic>;
                return _PersonCard(
                  personId: member['id'] as int?,
                  profilePath: member['profile_path'] as String?,
                  name: member['name'] as String? ?? '',
                  label: member['character'] as String? ?? '',
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final int? personId;
  final String? profilePath;
  final String name;
  final String label;
  final Color? labelColor;

  const _PersonCard({
    required this.profilePath,
    required this.name,
    required this.label,
    this.personId,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: personId != null
          ? () => context.push('/person/$personId?name=${Uri.encodeComponent(name)}')
          : null,
      child: SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: profilePath != null
                ? CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/w185$profilePath',
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: labelColor ?? Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    ),
    );
  }

  Widget _placeholder() => Container(
        width: 80, height: 110,
        color: const Color(0xFF2C2C2E),
        child: const Icon(Icons.person, color: Colors.grey),
      );
}

// ---------------------------------------------------------------------------
// Pending action sheet (movie is only in Pendientes)
// ---------------------------------------------------------------------------

enum _PendingStep { options, existingList, createList, review }

class _PendingActionSheet extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  const _PendingActionSheet({required this.tmdbId, required this.mediaType});

  @override
  State<_PendingActionSheet> createState() => _PendingActionSheetState();
}

class _PendingActionSheetState extends State<_PendingActionSheet> {
  _PendingStep _step = _PendingStep.options;
  final _listNameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  double? _rating;
  bool _saving = false;
  bool _recordWatch = true;
  DateTime _watchDate = DateTime.now();

  @override
  void dispose() {
    _listNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          if (_step != _PendingStep.options)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _step = _PendingStep.options),
              ),
            ),
          _buildStep(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      _PendingStep.options    => _buildOptions(context),
      _PendingStep.existingList => _buildExistingList(context),
      _PendingStep.createList => _buildCreateList(context),
      _PendingStep.review     => _buildReview(context),
    };
  }

  Widget _buildOptions(BuildContext context) {
    final listName = context.read<DetailProvider>().currentListName ?? 'lista';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('En $listName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        ListTile(
          leading: const Icon(Icons.playlist_add_rounded, color: Color(0xFF6C63FF)),
          title: const Text('Añadir a lista existente', style: TextStyle(color: Colors.white)),
          onTap: () => setState(() => _step = _PendingStep.existingList),
        ),
        ListTile(
          leading: const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
          title: const Text('Añadir a nueva lista', style: TextStyle(color: Colors.white)),
          onTap: () => setState(() => _step = _PendingStep.createList),
        ),
        ListTile(
          leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
          title: Text('Quitar de $listName', style: const TextStyle(color: Colors.redAccent)),
          onTap: () async {
            final detail = context.read<DetailProvider>();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context, rootNavigator: true).pop();
            final ok = await detail.removeFromAllLists(widget.tmdbId, widget.mediaType);
            messenger.showSnackBar(SnackBar(
              content: Text(ok ? 'Quitado de $listName' : detail.addError ?? 'Error'),
              backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
            ));
          },
        ),
      ],
    );
  }

  Widget _buildExistingList(BuildContext context) {
    final detail = context.watch<DetailProvider>();
    final nonDefaultLists = detail.userLists.where((l) => !l.isDefault).toList();

    if (nonDefaultLists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No tienes otras listas. Crea una nueva.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Selecciona una lista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        ...nonDefaultLists.map((list) => ListTile(
          leading: const Icon(Icons.list_rounded, color: Color(0xFF6C63FF)),
          title: Text(list.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text('${list.itemCount} títulos', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          onTap: () async {
            final ok = await context.read<DetailProvider>().addToList(list.id, widget.tmdbId, widget.mediaType, isDefault: false, listName: list.name);
            if (ok && mounted) setState(() => _step = _PendingStep.review);
          },
        )),
      ],
    );
  }

  Widget _buildCreateList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nueva lista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          TextField(
            controller: _listNameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre de la lista'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_listNameCtrl.text.trim().isEmpty) return;
                final ok = await context.read<DetailProvider>().createListAndAdd(
                  _listNameCtrl.text.trim(), widget.tmdbId, widget.mediaType,
                );
                if (ok && mounted) setState(() => _step = _PendingStep.review);
              },
              child: const Text('Crear y añadir'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Añade tu reseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          _WatchDateRow(
            recordWatch: _recordWatch,
            watchDate: _watchDate,
            onRecordChanged: (v) => setState(() => _recordWatch = v),
            onDateChanged: (d) => setState(() => _watchDate = d),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
              const SizedBox(width: 8),
              Text(
                _rating != null ? _rating!.toStringAsFixed(1) : '—',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(' / 10', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          Slider(
            value: _rating ?? 0,
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: const Color(0xFF6C63FF),
            inactiveColor: const Color(0xFF2C2C2E),
            onChanged: (v) => setState(() => _rating = v),
          ),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe tu opinión...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.edit_note_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final detail = context.read<DetailProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await detail.saveReview(widget.tmdbId, widget.mediaType, _rating, _noteCtrl.text);
                          if (_recordWatch) await detail.addToHistory(widget.tmdbId, widget.mediaType, _watchDate);
                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                          messenger.showSnackBar(SnackBar(
                            content: Text(ok ? 'Reseña guardada' : detail.reviewError ?? 'Error'),
                            backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                          ));
                        },
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar reseña'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () async {
                  if (_recordWatch) await context.read<DetailProvider>().addToHistory(widget.tmdbId, widget.mediaType, _watchDate);
                  if (mounted) Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text('Omitir', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current list action sheet (movie is in a non-default list)
// ---------------------------------------------------------------------------

enum _CurrentListStep { options, existingList, createList }

class _CurrentListActionSheet extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  const _CurrentListActionSheet({required this.tmdbId, required this.mediaType});

  @override
  State<_CurrentListActionSheet> createState() => _CurrentListActionSheetState();
}

class _CurrentListActionSheetState extends State<_CurrentListActionSheet> {
  _CurrentListStep _step = _CurrentListStep.options;
  final _listNameCtrl = TextEditingController();

  @override
  void dispose() {
    _listNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetailProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          if (_step != _CurrentListStep.options)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _step = _CurrentListStep.options),
              ),
            ),
          _buildStep(context, provider),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, DetailProvider provider) {
    return switch (_step) {
      _CurrentListStep.options      => _buildOptions(context, provider),
      _CurrentListStep.existingList => _buildExistingList(context, provider),
      _CurrentListStep.createList   => _buildCreateList(context),
    };
  }

  Widget _buildOptions(BuildContext context, DetailProvider provider) {
    final listName = provider.currentListName ?? 'la lista';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('En "$listName"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        ListTile(
          leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF6C63FF)),
          title: const Text('Mover a otra lista', style: TextStyle(color: Colors.white)),
          onTap: () => setState(() => _step = _CurrentListStep.existingList),
        ),
        ListTile(
          leading: const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
          title: const Text('Mover a nueva lista', style: TextStyle(color: Colors.white)),
          onTap: () => setState(() => _step = _CurrentListStep.createList),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
          title: const Text('Eliminar de la lista', style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            final detail = context.read<DetailProvider>();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context, rootNavigator: true).pop();
            final ok = await detail.removeFromAllLists(widget.tmdbId, widget.mediaType);
            messenger.showSnackBar(SnackBar(
              content: Text(ok ? 'Eliminado de la lista' : detail.addError ?? 'Error'),
              backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
            ));
          },
        ),
      ],
    );
  }

  Widget _buildExistingList(BuildContext context, DetailProvider provider) {
    final otherLists = provider.userLists.where((l) => l.id != provider.currentListId).toList();
    if (otherLists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No tienes otras listas disponibles.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Selecciona una lista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        ...otherLists.map((list) => ListTile(
          leading: Icon(list.isDefault ? Icons.bookmark_rounded : Icons.list_rounded, color: const Color(0xFF6C63FF)),
          title: Text(list.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text('${list.itemCount} títulos', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          onTap: () async {
            final ok = await context.read<DetailProvider>().addToList(
              list.id, widget.tmdbId, widget.mediaType,
              isDefault: list.isDefault, listName: list.name,
            );
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? 'Movido a "${list.name}"' : context.read<DetailProvider>().addError ?? 'Error'),
              backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
            ));
          },
        )),
      ],
    );
  }

  Widget _buildCreateList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nueva lista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          TextField(
            controller: _listNameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre de la lista'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_listNameCtrl.text.trim().isEmpty) return;
                final name = _listNameCtrl.text.trim();
                final ok = await context.read<DetailProvider>().createListAndAdd(name, widget.tmdbId, widget.mediaType);
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Movido a "$name"' : context.read<DetailProvider>().addError ?? 'Error'),
                  backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                ));
              },
              child: const Text('Crear y mover'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AddToListSheet extends StatefulWidget {
  final int tmdbId;
  final String mediaType;

  const _AddToListSheet({required this.tmdbId, required this.mediaType});

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  bool _showReview = false;
  double? _rating;
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  bool _recordWatch = true;
  DateTime _watchDate = DateTime.now();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<DetailProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
          if (_showReview)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _showReview = false),
              ),
            )
          else
            const SizedBox(height: 16),
          if (!_showReview) ...[
            const Text('Añadir a lista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            ...detail.userLists
                .where((list) => list.mediaType == null || list.mediaType == widget.mediaType)
                .map((list) => ListTile(
                      leading: const Icon(Icons.list_rounded, color: Color(0xFF6C63FF)),
                      title: Text(list.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${list.itemCount} títulos', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await detail.addToList(
                          list.id, widget.tmdbId, widget.mediaType,
                          isDefault: list.isDefault, listName: list.name,
                        );
                        if (!ok) {
                          messenger.showSnackBar(SnackBar(
                            content: Text(detail.addError ?? 'Error'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (list.isDefault) {
                          Navigator.of(context, rootNavigator: true).pop();
                          messenger.showSnackBar(SnackBar(
                            content: Text('Añadido a "${list.name}"'),
                            backgroundColor: const Color(0xFF6C63FF),
                          ));
                        } else {
                          setState(() => _showReview = true);
                        }
                      },
                    )),
            const SizedBox(height: 16),
          ] else ...[
            _buildReview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Añade tu reseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          _WatchDateRow(
            recordWatch: _recordWatch,
            watchDate: _watchDate,
            onRecordChanged: (v) => setState(() => _recordWatch = v),
            onDateChanged: (d) => setState(() => _watchDate = d),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
              const SizedBox(width: 8),
              Text(
                _rating != null ? _rating!.toStringAsFixed(1) : '—',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(' / 10', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          Slider(
            value: _rating ?? 0,
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: const Color(0xFF6C63FF),
            inactiveColor: const Color(0xFF2C2C2E),
            onChanged: (v) => setState(() => _rating = v),
          ),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe tu opinión...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.edit_note_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final detail    = context.read<DetailProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await detail.saveReview(widget.tmdbId, widget.mediaType, _rating, _noteCtrl.text);
                          if (_recordWatch) await detail.addToHistory(widget.tmdbId, widget.mediaType, _watchDate);
                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                          messenger.showSnackBar(SnackBar(
                            content: Text(ok ? 'Reseña guardada' : detail.reviewError ?? 'Error'),
                            backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                          ));
                        },
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar reseña'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () async {
                  if (_recordWatch) await context.read<DetailProvider>().addToHistory(widget.tmdbId, widget.mediaType, _watchDate);
                  if (mounted) Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text('Omitir', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TV add flow sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TvAddFlowSheet extends StatefulWidget {
  final int tmdbId;
  final SeasonProvider seasonProvider;
  const _TvAddFlowSheet({required this.tmdbId, required this.seasonProvider});

  @override
  State<_TvAddFlowSheet> createState() => _TvAddFlowSheetState();
}

class _TvAddFlowSheetState extends State<_TvAddFlowSheet> {
  bool? _watchedCompletely;
  bool _showNewList = false;
  bool _showReview  = false;
  final _newListCtrl  = TextEditingController();
  final _reviewNoteCtrl = TextEditingController();
  double? _rating;
  bool _saving        = false;
  bool _reviewSaving  = false;
  bool _recordWatch   = true;
  DateTime _watchDate = DateTime.now();

  @override
  void dispose() {
    _newListCtrl.dispose();
    _reviewNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleNo(BuildContext context) async {
    final detail      = context.read<DetailProvider>();
    final messenger   = ScaffoldMessenger.of(context);
    final viewingList = detail.userLists.firstWhere(
      (l) => l.isDefault && l.mediaType == 'tv',
      orElse: () => detail.userLists.first,
    );
    Navigator.of(context, rootNavigator: true).pop();
    final ok = await detail.addToList(
      viewingList.id, widget.tmdbId, 'tv',
      isDefault: true, listName: viewingList.name,
    );
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Añadido a "${viewingList.name}"' : detail.addError ?? 'Error'),
      backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
    ));
  }

  Future<void> _handleListSelect(BuildContext context, UserList list) async {
    setState(() => _saving = true);
    final detail    = context.read<DetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await detail.addToList(list.id, widget.tmdbId, 'tv', isDefault: false, listName: list.name);
    if (!ok) {
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(SnackBar(content: Text(detail.addError ?? 'Error'), backgroundColor: Colors.red));
      return;
    }
    await detail.markAllEpisodesWatched(widget.tmdbId);
    await widget.seasonProvider.loadProgress(widget.tmdbId);
    if (!mounted) return;
    setState(() { _saving = false; _showReview = true; });
  }

  Future<void> _handleNewList(BuildContext context) async {
    final name = _newListCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final detail    = context.read<DetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await detail.createListAndAdd(name, widget.tmdbId, 'tv');
    if (!ok) {
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(SnackBar(content: Text(detail.addError ?? 'Error'), backgroundColor: Colors.red));
      return;
    }
    await detail.markAllEpisodesWatched(widget.tmdbId);
    await widget.seasonProvider.loadProgress(widget.tmdbId);
    if (!mounted) return;
    setState(() { _saving = false; _showReview = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
          ),
          if (_showReview)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _showReview = false),
              ),
            )
          else
            const SizedBox(height: 20),
          if (_showReview) ..._buildReviewStep(context)
          else if (_watchedCompletely == null) ..._buildStep1(context)
          else ..._buildStep2(context),
        ],
      ),
    );
  }

  List<Widget> _buildReviewStep(BuildContext context) => [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Añade tu reseña',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WatchDateRow(
                recordWatch: _recordWatch,
                watchDate: _watchDate,
                onRecordChanged: (v) => setState(() => _recordWatch = v),
                onDateChanged: (d) => setState(() => _watchDate = d),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _rating != null ? _rating!.toStringAsFixed(1) : '—',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(' / 10', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              Slider(
                value: _rating ?? 0,
                min: 0, max: 10, divisions: 20,
                activeColor: const Color(0xFF6C63FF),
                inactiveColor: const Color(0xFF2C2C2E),
                onChanged: (v) => setState(() => _rating = v),
              ),
              TextField(
                controller: _reviewNoteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu opinión...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.edit_note_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _reviewSaving
                          ? null
                          : () async {
                              setState(() => _reviewSaving = true);
                              final detail    = context.read<DetailProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await detail.saveReview(widget.tmdbId, 'tv', _rating, _reviewNoteCtrl.text);
                              if (_recordWatch) await detail.addToHistory(widget.tmdbId, 'tv', _watchDate);
                              if (!mounted) return;
                              Navigator.of(context, rootNavigator: true).pop();
                              messenger.showSnackBar(SnackBar(
                                content: Text(ok ? 'Reseña guardada' : detail.reviewError ?? 'Error'),
                                backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                              ));
                            },
                      child: _reviewSaving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar reseña'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      if (_recordWatch) await context.read<DetailProvider>().addToHistory(widget.tmdbId, 'tv', _watchDate);
                      if (mounted) Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Text('Omitir', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ];

  List<Widget> _buildStep1(BuildContext context) => [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '¿Has visto esta serie completa?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Sí, completa',
                  onTap: () => setState(() => _watchedCompletely = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceButton(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Estoy viéndola',
                  onTap: () => _handleNo(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ];

  List<Widget> _buildStep2(BuildContext context) {
    final detail         = context.watch<DetailProvider>();
    final nonDefaultLists = detail.userLists.where((l) => !l.isDefault).toList();

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              onPressed: () => setState(() { _watchedCompletely = null; _showNewList = false; }),
            ),
            const Text(
              '¿En qué lista guardarla?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      if (nonDefaultLists.isEmpty && !_showNewList)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('No tienes listas personalizadas aún.', style: TextStyle(color: Colors.grey.shade400)),
        ),
      ...nonDefaultLists.map((list) => ListTile(
            leading: const Icon(Icons.list_rounded, color: Color(0xFF6C63FF)),
            title: Text(list.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('${list.itemCount} títulos', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            onTap: _saving ? null : () => _handleListSelect(context, list),
          )),
      if (_showNewList)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newListCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Nombre de la lista'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded, color: Color(0xFF6C63FF)),
                onPressed: _saving ? null : () => _handleNewList(context),
              ),
            ],
          ),
        )
      else
        ListTile(
          leading: const Icon(Icons.add_rounded, color: Color(0xFF6C63FF)),
          title: const Text('Nueva lista', style: TextStyle(color: Color(0xFF6C63FF))),
          onTap: () => setState(() => _showNewList = true),
        ),
      const SizedBox(height: 16),
    ];
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChoiceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Watch date row (reusable inside review steps)
// ─────────────────────────────────────────────────────────────────────────────

class _WatchDateRow extends StatelessWidget {
  final bool recordWatch;
  final DateTime watchDate;
  final ValueChanged<bool> onRecordChanged;
  final ValueChanged<DateTime> onDateChanged;

  const _WatchDateRow({
    required this.recordWatch,
    required this.watchDate,
    required this.onRecordChanged,
    required this.onDateChanged,
  });

  static String _fmt(DateTime d) {
    const m = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${d.day} de ${m[d.month - 1]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            const Text('Registrar como vista', style: TextStyle(color: Colors.white, fontSize: 13)),
            const Spacer(),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: recordWatch,
                onChanged: onRecordChanged,
                activeColor: const Color(0xFF6C63FF),
                activeTrackColor: const Color(0xFF6C63FF).withOpacity(0.3),
                inactiveThumbColor: Colors.grey.shade600,
                inactiveTrackColor: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        if (recordWatch)
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: watchDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (_, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF)),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(_fmt(watchDate), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_rounded, size: 11, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade800, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Series status badge
// ─────────────────────────────────────────────────────────────────────────────

class _SeriesStatusBadge extends StatelessWidget {
  final String status;
  const _SeriesStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String label;

    switch (status) {
      case 'Ended':
        icon  = Icons.check_circle_outline;
        color = const Color(0xFF4CAF50);
        label = 'Finalizada';
      case 'Canceled':
        icon  = Icons.cancel_outlined;
        color = Colors.redAccent;
        label = 'Cancelada';
      case 'Returning Series':
        icon  = Icons.replay_rounded;
        color = const Color(0xFF6C63FF);
        label = 'En emisión';
      case 'In Production':
        icon  = Icons.build_circle_outlined;
        color = Colors.orange;
        label = 'En producción';
      case 'Planned':
        icon  = Icons.schedule_rounded;
        color = Colors.blueGrey;
        label = 'Anunciada';
      default:
        icon  = Icons.info_outline;
        color = Colors.grey;
        label = status;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seasons / Episodes
// ─────────────────────────────────────────────────────────────────────────────

class _SeasonsSection extends StatefulWidget {
  final int tmdbId;
  final List<dynamic> seasons;

  const _SeasonsSection({required this.tmdbId, required this.seasons});

  @override
  State<_SeasonsSection> createState() => _SeasonsSectionState();
}

class _SeasonsSectionState extends State<_SeasonsSection> {
  late int _selectedSeason;
  bool _completionShown = false;

  List<dynamic> get _validSeasons => widget.seasons
      .where((s) => (s['season_number'] as num?)?.toInt() != 0)
      .toList();

  int get _totalEpisodes => widget.seasons
      .where((s) => (s['season_number'] as num?)?.toInt() != 0)
      .fold(0, (sum, s) => sum + ((s['episode_count'] as num?)?.toInt() ?? 0));

  @override
  void initState() {
    super.initState();
    final valid = _validSeasons;
    _selectedSeason = valid.isNotEmpty
        ? (valid.first['season_number'] as num).toInt()
        : 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeasonProvider>().loadSeason(widget.tmdbId, _selectedSeason);
    });
  }

  void _triggerCompletionCheck(bool wasWatched) {
    if (wasWatched || _completionShown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sp    = context.read<SeasonProvider>();
      final total = _totalEpisodes;
      if (total <= 0 || sp.watchedTotal < total) return;

      final dp = context.read<DetailProvider>();
      if (!dp.isInList || dp.inNonDefaultList) return;
      if (dp.currentListName != 'Series que estoy viendo') return;

      final status = dp.detail?['status'] as String?;
      if (status != 'Ended' && status != 'Canceled') return;

      _completionShown = true;
      _showCompletionSheet();
    });
  }

  void _showCompletionSheet() async {
    final detail = context.read<DetailProvider>();
    await detail.loadUserLists();
    if (!mounted) return;
    final seriesName = (detail.detail?['name'] as String?) ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: detail,
        child: _CompletionSheet(tmdbId: widget.tmdbId, seriesName: seriesName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeasonProvider>();
    final valid = _validSeasons;
    if (valid.isEmpty) return const SizedBox.shrink();

    final total   = provider.episodes.length;
    final watched = provider.watchedCount(_selectedSeason);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Episodios',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),

        // Season selector
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: valid.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final n = (valid[i]['season_number'] as num).toInt();
              final selected = n == _selectedSeason;
              return GestureDetector(
                onTap: () {
                  if (_selectedSeason == n) return;
                  setState(() => _selectedSeason = n);
                  provider.loadSeason(widget.tmdbId, n);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'T$n',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey.shade400,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Progress bar
        if (!provider.loadingSeason && total > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: watched / total,
                    backgroundColor: const Color(0xFF2C2C2E),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$watched / $total vistos',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),

        if (provider.loadingSeason)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...provider.episodes.map((e) {
            final ep = e as Map<String, dynamic>;
            final epNum = (ep['episode_number'] as num?)?.toInt() ?? 0;
            final isWatched = provider.isWatched(_selectedSeason, epNum);
            return _EpisodeTile(
              episode: ep,
              watched: isWatched,
              onToggle: () {
                provider.toggleEpisode(widget.tmdbId, _selectedSeason, epNum);
                _triggerCompletionCheck(isWatched);
              },
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion sheet
// ─────────────────────────────────────────────────────────────────────────────

enum _CompletionStep { list, review }

class _CompletionSheet extends StatefulWidget {
  final int tmdbId;
  final String seriesName;
  const _CompletionSheet({required this.tmdbId, required this.seriesName});

  @override
  State<_CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<_CompletionSheet> {
  _CompletionStep _step = _CompletionStep.list;
  bool _showNewList = false;
  final _listCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  double? _rating;
  bool _saving = false;
  bool _recordWatch = true;
  DateTime _watchDate = DateTime.now();

  @override
  void dispose() {
    _listCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addToList(BuildContext context, UserList list) async {
    final detail = context.read<DetailProvider>();
    final ok = await detail.addToList(list.id, widget.tmdbId, 'tv', isDefault: false, listName: list.name);
    if (ok && mounted) setState(() => _step = _CompletionStep.review);
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final name = _listCtrl.text.trim();
    if (name.isEmpty) return;
    final detail = context.read<DetailProvider>();
    final ok = await detail.createListAndAdd(name, widget.tmdbId, 'tv');
    if (ok && mounted) setState(() => _step = _CompletionStep.review);
  }

  Future<void> _removeOnly(BuildContext context) async {
    final detail    = context.read<DetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context, rootNavigator: true).pop();
    final ok = await detail.removeFromAllLists(widget.tmdbId, 'tv');
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Serie eliminada de la lista' : detail.addError ?? 'Error'),
      backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
          if (_step == _CompletionStep.review)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _step = _CompletionStep.list),
              ),
            )
          else
            const SizedBox(height: 20),
          if (_step == _CompletionStep.list) ..._buildListStep(context),
          if (_step == _CompletionStep.review) ..._buildReviewStep(context),
        ],
      ),
    );
  }

  List<Widget> _buildListStep(BuildContext context) {
    final detail          = context.watch<DetailProvider>();
    final nonDefaultLists = detail.userLists.where((l) => !l.isDefault).toList();

    return [
      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC107), size: 52),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          '¡Has terminado "${widget.seriesName}"!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Ya has visto todos los episodios. ¿Dónde quieres archivarla?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      ),
      const SizedBox(height: 16),
      if (nonDefaultLists.isEmpty && !_showNewList)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('No tienes listas personalizadas aún.',
              style: TextStyle(color: Colors.grey.shade400), textAlign: TextAlign.center),
        ),
      ...nonDefaultLists.map((list) => ListTile(
            leading: const Icon(Icons.list_rounded, color: Color(0xFF6C63FF)),
            title: Text(list.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('${list.itemCount} títulos',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            onTap: () => _addToList(context, list),
          )),
      if (_showNewList)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _listCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Nombre de la lista'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded, color: Color(0xFF6C63FF)),
                onPressed: () => _createAndAdd(context),
              ),
            ],
          ),
        )
      else
        ListTile(
          leading: const Icon(Icons.add_rounded, color: Color(0xFF6C63FF)),
          title: const Text('Nueva lista', style: TextStyle(color: Color(0xFF6C63FF))),
          onTap: () => setState(() => _showNewList = true),
        ),
      Divider(color: Colors.grey.shade800, height: 1),
      ListTile(
        leading: Icon(Icons.remove_circle_outline, color: Colors.grey.shade500),
        title: Text('Solo quitar de la lista', style: TextStyle(color: Colors.grey.shade500)),
        onTap: () => _removeOnly(context),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildReviewStep(BuildContext context) => [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Añade tu reseña',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WatchDateRow(
                recordWatch: _recordWatch,
                watchDate: _watchDate,
                onRecordChanged: (v) => setState(() => _recordWatch = v),
                onDateChanged: (d) => setState(() => _watchDate = d),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _rating != null ? _rating!.toStringAsFixed(1) : '—',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(' / 10', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              Slider(
                value: _rating ?? 0,
                min: 0,
                max: 10,
                divisions: 20,
                activeColor: const Color(0xFF6C63FF),
                inactiveColor: const Color(0xFF2C2C2E),
                onChanged: (v) => setState(() => _rating = v),
              ),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu opinión...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.edit_note_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              final detail    = context.read<DetailProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await detail.saveReview(
                                  widget.tmdbId, 'tv', _rating, _noteCtrl.text);
                              if (_recordWatch) await detail.addToHistory(widget.tmdbId, 'tv', _watchDate);
                              if (!mounted) return;
                              Navigator.of(context, rootNavigator: true).pop();
                              messenger.showSnackBar(SnackBar(
                                content: Text(ok ? 'Reseña guardada' : detail.reviewError ?? 'Error'),
                                backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                              ));
                            },
                      child: _saving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar reseña'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      if (_recordWatch) await context.read<DetailProvider>().addToHistory(widget.tmdbId, 'tv', _watchDate);
                      if (mounted) Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Text('Omitir', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ];
}

class _EpisodeTile extends StatefulWidget {
  final Map<String, dynamic> episode;
  final bool watched;
  final VoidCallback onToggle;

  const _EpisodeTile({
    required this.episode,
    required this.watched,
    required this.onToggle,
  });

  @override
  State<_EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<_EpisodeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
  ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _handleToggle() {
    _bounce.forward(from: 0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final epNum     = (widget.episode['episode_number'] as num?)?.toInt() ?? 0;
    final name      = widget.episode['name'] as String? ?? '';
    final stillPath = widget.episode['still_path'] as String?;
    final runtime   = (widget.episode['runtime'] as num?)?.toInt();

    return InkWell(
      onTap: _handleToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: stillPath != null
                  ? CachedNetworkImage(
                      imageUrl: 'https://image.tmdb.org/t/p/w185$stillPath',
                      width: 90,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _numBox(epNum),
                      errorWidget: (_, __, ___) => _numBox(epNum),
                    )
                  : _numBox(epNum),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  if (runtime != null && runtime > 0)
                    Text(
                      '${runtime}min',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _scale,
              builder: (_, child) => Transform.scale(
                scale: _scale.value * 0.8,
                child: child,
              ),
              child: Switch(
                value: widget.watched,
                onChanged: (_) => _handleToggle(),
                activeColor: const Color(0xFF6C63FF),
                activeTrackColor: const Color(0xFF6C63FF).withOpacity(0.3),
                inactiveThumbColor: Colors.grey.shade600,
                inactiveTrackColor: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numBox(int n) => Container(
        width: 90,
        height: 56,
        color: const Color(0xFF2C2C2E),
        child: Center(
          child: Text(
            'E${n.toString().padLeft(2, '0')}',
            style: const TextStyle(
                color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      );
}
