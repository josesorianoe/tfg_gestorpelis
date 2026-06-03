import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../../../core/models/user_list.dart';
import '../../../shared/widgets/media_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
      _maybeShowAdminPopup();
    });
  }

  Future<void> _maybeShowAdminPopup() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isAdmin) return;

    final adminProvider = context.read<AdminProvider>();
    if (adminProvider.loginPopupShown) return;

    adminProvider.markLoginPopupShown();
    await adminProvider.loadUsers();
    if (!mounted) return;

    final count = adminProvider.pendingDeletionCount;
    if (count == 0) return;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Solicitudes de baja',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          count == 1
              ? 'Hay 1 usuario que ha solicitado la eliminación de su cuenta.'
              : 'Hay $count usuarios que han solicitado la eliminación de su cuenta.',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text('Cerrar', style: TextStyle(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.push('/admin/users');
            },
            child: const Text('Ver ahora', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_rounded, color: Color(0xFF6C63FF), size: 22),
            const SizedBox(width: 8),
            const Text('GestorPelis'),
          ],
        ),
      ),
      body: Consumer<HomeProvider>(
        builder: (_, provider, __) {
          if (provider.loading && provider.discover.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.discover.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey.shade600, size: 48),
                  const SizedBox(height: 12),
                  Text(provider.error!, style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => provider.refresh(), child: const Text('Reintentar')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (provider.discover.isNotEmpty) ...[
                  _SectionHeader(title: 'Populares ahora', onMore: () => context.push('/popular')),
                  SizedBox(
                    height: 245,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.discover.length,
                      itemBuilder: (_, i) {
                        final item = provider.discover[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: MediaCard(
                            posterUrl: item.fullPosterUrl,
                            title: item.title,
                            year: item.year,
                            rating: item.voteAverage,
                            onTap: () => context.push(
                              '/detail/${item.tmdbId}?type=${item.mediaType}&title=${Uri.encodeComponent(item.title)}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _SectionHeader(title: 'Mi biblioteca', onMore: null),
                if (provider.listsWithItems.isNotEmpty) ...[
                  ...provider.listsWithItems
                      .where((l) => l.isDefault)
                      .map((list) => _ListCarousel(userList: list)),
                  if (provider.listsWithItems.any((l) => !l.isDefault))
                    _CustomListsSection(
                      lists: provider.listsWithItems.where((l) => !l.isDefault).toList(),
                    ),
                ] else if (!provider.loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.movie_filter_outlined, size: 52, color: Colors.grey.shade700),
                        const SizedBox(height: 14),
                        const Text(
                          'Tu biblioteca está vacía',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Busca títulos y añádelos a tus listas',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          if (onMore != null)
            TextButton(onPressed: onMore, child: const Text('Ver todo')),
        ],
      ),
    );
  }
}

class _CustomListsSection extends StatefulWidget {
  final List<UserList> lists;
  const _CustomListsSection({required this.lists});

  @override
  State<_CustomListsSection> createState() => _CustomListsSectionState();
}

class _CustomListsSectionState extends State<_CustomListsSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final total = widget.lists.fold(0, (sum, l) => sum + l.itemCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.folder_rounded, color: Color(0xFF6C63FF), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Mis listas (${widget.lists.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$total títulos',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  children: widget.lists.map((list) => _ListCarousel(userList: list)).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ListCarousel extends StatelessWidget {
  final UserList userList;

  const _ListCarousel({required this.userList});

  @override
  Widget build(BuildContext context) {
    final items = (userList.items ?? []).where((i) => i.mediaItem != null).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
          child: Row(
            children: [
              if (userList.isDefault)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.bookmark_rounded, color: Color(0xFF6C63FF), size: 16),
                ),
              Expanded(
                child: Text(
                  userList.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/lists/${userList.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Ver todo'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 245,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final media = item.mediaItem!;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MediaCard(
                  posterUrl: media.fullPosterUrl,
                  title: media.title,
                  year: media.year,
                  rating: media.voteAverage,
                  userRating: item.userRating,
                  onTap: () => context.push(
                    '/detail/${media.tmdbId}?type=${media.mediaType}&title=${Uri.encodeComponent(media.title)}',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
