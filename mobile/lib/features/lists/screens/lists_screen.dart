import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/lists_provider.dart';
import '../../../core/models/user_list.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListsProvider>().loadLists();
    });
  }

  void _showEditDialog(UserList list) {
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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final provider = context.read<ListsProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context, rootNavigator: true).pop();
              final ok = await provider.updateList(list.id, nameCtrl.text, descCtrl.text);
              messenger.showSnackBar(SnackBar(
                content: Text(ok ? 'Lista actualizada' : provider.error ?? 'Error'),
                backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Nueva lista', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final provider = context.read<ListsProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context, rootNavigator: true).pop();
              final created = await provider.createList(nameCtrl.text, descCtrl.text);
              messenger.showSnackBar(SnackBar(
                content: Text(created != null ? 'Lista "${created.name}" creada' : provider.error ?? 'Error al crear la lista'),
                backgroundColor: created != null ? const Color(0xFF6C63FF) : Colors.red,
              ));
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis listas')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add_rounded),
      ),
      body: Consumer<ListsProvider>(
        builder: (_, provider, __) {
          if (provider.loading) return const Center(child: CircularProgressIndicator());

          if (provider.lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  const Text('No tienes listas aún', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Crea una lista para organizar tus películas', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadLists,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.lists.length,
              itemBuilder: (_, i) {
                final list = provider.lists[i];
                return _ListTile(
                  list: list,
                  onEdit: list.isDefault ? null : () => _showEditDialog(list),
                  onDelete: list.isDefault
                      ? null
                      : () async {
                          final ok = await provider.deleteList(list.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(provider.error ?? 'Error'), backgroundColor: Colors.red),
                            );
                          }
                        },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final UserList list;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ListTile({required this.list, this.onEdit, this.onDelete});

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Eliminar lista', style: TextStyle(color: Colors.white)),
          content: Text(
            '¿Seguro que quieres eliminar "${list.name}"? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/lists/${list.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  list.isDefault ? Icons.bookmark_rounded : Icons.list_rounded,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(list.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                        if (list.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Por defecto',
                                style: TextStyle(color: Color(0xFF6C63FF), fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    if (list.description != null && list.description!.isNotEmpty)
                      Text(list.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Text('${list.itemCount}', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(width: 8),
              if (!list.isDefault)
                PopupMenuButton<String>(
                  color: const Color(0xFF2C2C2E),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      onEdit?.call();
                    } else if (v == 'delete') {
                      final confirmed = await _confirmDelete(context);
                      if (confirmed == true) onDelete?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                          SizedBox(width: 10),
                          Text('Editar', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(Icons.more_vert, color: Colors.grey.shade600),
                )
              else
                const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );

    if (list.isDefault) return card;

    return Dismissible(
      key: ValueKey(list.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(height: 4),
            Text('Eliminar', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: card,
    );
  }
}
