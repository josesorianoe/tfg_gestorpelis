import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/lists_provider.dart';
import '../../../core/models/list_item.dart';
import '../../../features/home/providers/home_provider.dart';
import '../../../shared/widgets/poster_image.dart';

class ListDetailScreen extends StatefulWidget {
  final int listId;
  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _itemsChanged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListsProvider>().loadListDetail(widget.listId);
    });
  }

  void _showItemOptions(BuildContext context, ListItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ItemOptionsSheet(
        listId: widget.listId,
        item: item,
        onItemRemoved: () => setState(() => _itemsChanged = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _itemsChanged) {
          context.read<HomeProvider>().refreshLists();
        }
      },
      child: Consumer<ListsProvider>(
      builder: (_, provider, __) {
        final list = provider.current;

        return Scaffold(
          appBar: AppBar(
            title: Text(list?.name ?? 'Lista'),
            actions: [
              if (list != null && !list.isDefault)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(context, provider),
                ),
            ],
          ),
          body: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : list == null
                  ? const Center(child: Text('Lista no encontrada', style: TextStyle(color: Colors.grey)))
                  : list.items == null || list.items!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.movie_filter_outlined, size: 64, color: Colors.grey.shade700),
                              const SizedBox(height: 16),
                              const Text('Lista vacía', style: TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Busca títulos y añádelos aquí', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.loadListDetail(widget.listId),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: list.items!.length,
                            itemBuilder: (_, i) {
                              final item = list.items![i];
                              return _ItemCard(
                                item: item,
                                onTap: () {
                                  if (item.mediaItem != null) {
                                    context.push(
                                      '/detail/${item.mediaItem!.tmdbId}?type=${item.mediaItem!.mediaType}&title=${Uri.encodeComponent(item.mediaItem!.title)}',
                                    );
                                  }
                                },
                                onLongPress: () => _showItemOptions(context, item),
                              );
                            },
                          ),
                        ),
        );
      },
      ), // Consumer
    ); // PopScope
  }

  void _showEditDialog(BuildContext context, ListsProvider provider) {
    final list = provider.current!;
    final nameCtrl = TextEditingController(text: list.name);
    final descCtrl = TextEditingController(text: list.description ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Editar lista', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await provider.updateList(list.id, nameCtrl.text, descCtrl.text);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ListItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ItemCard({required this.item, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final media = item.mediaItem;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          PosterImage(
            url: media?.fullPosterUrl,
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(10),
          ),
          if (item.watched)
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
          if (item.userRating != null)
            Positioned(
              bottom: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 10),
                    const SizedBox(width: 2),
                    Text(
                      item.userRating!.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Text(
                media?.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemOptionsSheet extends StatelessWidget {
  final int listId;
  final ListItem item;
  final VoidCallback? onItemRemoved;

  const _ItemOptionsSheet({required this.listId, required this.item, this.onItemRemoved});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ListsProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Text(item.mediaItem?.title ?? 'Opciones',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        ListTile(
          leading: Icon(item.watched ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF6C63FF)),
          title: Text(item.watched ? 'Marcar como no vista' : 'Marcar como vista', style: const TextStyle(color: Colors.white)),
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await provider.updateItem(listId, item.id, {'watched': !item.watched});
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Eliminar de la lista', style: TextStyle(color: Colors.red)),
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await provider.removeItem(listId, item.id);
            onItemRemoved?.call();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
