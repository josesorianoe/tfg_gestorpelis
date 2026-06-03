import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  Future<void> _confirmDelete(BuildContext context, AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Eliminar usuario', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Seguro que quieres eliminar a "${user.name}" (${user.email})?\nSe eliminarán todas sus listas e historial.',
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

    if (confirmed != true || !context.mounted) return;

    final provider   = context.read<AdminProvider>();
    final messenger  = ScaffoldMessenger.of(context);
    final ok         = await provider.deleteUser(user.id);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Usuario "${user.name}" eliminado' : provider.error ?? 'Error'),
      backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de usuarios')),
      body: Consumer<AdminProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey.shade600, size: 48),
                  const SizedBox(height: 12),
                  Text(provider.error!, style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: provider.loadUsers,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final pendingCount = provider.users.where((u) => u.deletionRequested).length;

          return RefreshIndicator(
            onRefresh: provider.loadUsers,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${provider.users.length} usuarios registrados',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '$pendingCount solicitud${pendingCount > 1 ? 'es' : ''} de baja',
                                style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.users.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade800, height: 1),
                    itemBuilder: (_, i) {
                      final user   = provider.users[i];
                      final isSelf = user.id == currentUserId;

                      return Container(
                        decoration: user.deletionRequested
                            ? BoxDecoration(
                                color: Colors.red.shade900.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: user.deletionRequested
                                ? Colors.red.shade900
                                : user.isAdmin
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFF2C2C2E),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                                      : Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user.isAdmin ? 'Admin' : 'Usuario',
                                  style: TextStyle(
                                    color: user.isAdmin ? const Color(0xFF6C63FF) : Colors.grey.shade400,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Tú',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                  ),
                                ),
                              ],
                              if (user.deletionRequested) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade900.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_forever_rounded, color: Colors.red.shade300, size: 10),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Solicita baja',
                                        style: TextStyle(color: Colors.red.shade300, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            user.email,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          trailing: isSelf
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: user.deletionRequested ? Colors.red.shade400 : Colors.redAccent,
                                  ),
                                  tooltip: 'Eliminar usuario',
                                  onPressed: () => _confirmDelete(context, user),
                                ),
                        ),
                      );
                    },
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
