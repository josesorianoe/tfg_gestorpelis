import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user.dart';
import '../../../core/models/watch_history_entry.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadHistory();
      final user = context.read<AuthProvider>().user;
      if (user != null && user.isAdmin) {
        context.read<AdminProvider>().loadUsers();
      }
    });
  }
  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user!;
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final form = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Mínimo 2 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              Consumer<ProfileProvider>(
                builder: (_, provider, __) => ElevatedButton(
                  onPressed: provider.saving
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          final ok = await provider.updateProfile(
                            nameCtrl.text,
                            emailCtrl.text,
                            onSuccess: (u) => context.read<AuthProvider>().updateUser(u),
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Perfil actualizado' : provider.error ?? 'Error'),
                                backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                              ),
                            );
                          }
                        },
                  child: provider.saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar cambios'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final currCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final form = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextFormField(
                controller: currCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 16),
              Consumer<ProfileProvider>(
                builder: (_, provider, __) => ElevatedButton(
                  onPressed: provider.saving
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          final ok = await provider.changePassword(currCtrl.text, newCtrl.text);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Contraseña cambiada' : provider.error ?? 'Error'),
                                backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
                              ),
                            );
                          }
                        },
                  child: const Text('Cambiar contraseña'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF6C63FF),
                  child: Text(user.initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (user.isAdmin) ...[
            Consumer<AdminProvider>(
              builder: (_, adminProvider, __) => _AdminOptionTile(
                pendingCount: adminProvider.pendingDeletionCount,
                onTap: () => context.push('/admin/users'),
              ),
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 32),
          ],
          _OptionTile(
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            onTap: () => _showEditProfile(context),
          ),
          _OptionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Cambiar contraseña',
            onTap: () => _showChangePassword(context),
          ),
          const Divider(color: Color(0xFF2C2C2E), height: 32),
          _WatchHistorySection(),
          const Divider(color: Color(0xFF2C2C2E), height: 32),
          if (!user.isAdmin) _DeleteAccountTile(user: user),
          _OptionTile(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            color: Colors.red,
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                content: const Text('¿Estás seguro?', style: TextStyle(color: Colors.grey)),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Cancelar')),
                  TextButton(
                    onPressed: () => context.read<AuthProvider>().logout(),
                    child: const Text('Salir', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchHistorySection extends StatefulWidget {
  @override
  State<_WatchHistorySection> createState() => _WatchHistorySectionState();
}

class _WatchHistorySectionState extends State<_WatchHistorySection> {
  bool _expanded = true;

  static const _months = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  static String _monthLabel(String key) {
    final parts = key.split('-');
    return '${_months[int.parse(parts[1])]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final total = provider.history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text('Historial de visionado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$total',
                        style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                const Spacer(),
                if (provider.historyLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (!provider.historyLoading && provider.history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aún no has registrado ningún título visto.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      )
                    else
                      ...provider.historyByMonth.entries.map((entry) {
                        final label = _monthLabel(entry.key);
                        final items = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(label,
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2E),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('${items.length}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...items.map((e) => _HistoryTile(entry: e)),
                          ],
                        );
                      }),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WatchHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => context.read<ProfileProvider>().removeFromHistory(entry.id),
      child: InkWell(
        onTap: () => context.push(
          '/detail/${entry.tmdbId}?type=${entry.mediaType}&title=${Uri.encodeComponent(entry.title)}',
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: entry.fullPosterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: entry.fullPosterUrl,
                        width: 42,
                        height: 63,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.isMovie ? 'Película' : 'Serie',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dayLabel(entry.watchedOn),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade700, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime d) {
    const m = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${d.day} de ${m[d.month]}';
  }

  Widget _placeholder() => Container(
        width: 42,
        height: 63,
        color: const Color(0xFF2C2C2E),
        child: const Icon(Icons.movie_rounded, color: Colors.grey, size: 20),
      );
}

class _AdminOptionTile extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const _AdminOptionTile({required this.pendingCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6C63FF)),
      title: const Text(
        'Gestión de usuarios',
        style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade700),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _DeleteAccountTile extends StatelessWidget {
  final User user;
  const _DeleteAccountTile({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.deletionRequested) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade900),
        title: Text(
          'Eliminar cuenta',
          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Solicitud enviada. El administrador procesará la eliminación.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Icon(Icons.hourglass_top_rounded, color: Colors.red.shade900, size: 18),
        enabled: false,
      );
    }

    return _OptionTile(
      icon: Icons.delete_forever_rounded,
      title: 'Eliminar cuenta',
      color: Colors.redAccent,
      onTap: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Solicitar eliminación', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Se enviará una solicitud al administrador para eliminar tu cuenta y todos tus datos.\n\n¿Deseas continuar?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Solicitar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final auth      = context.read<AuthProvider>();
    final provider  = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await provider.requestDeletion(
      onSuccess: (u) => auth.updateUser(u),
    );

    if (context.mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(ok ? 'Solicitud enviada correctamente' : provider.error ?? 'Error'),
        backgroundColor: ok ? const Color(0xFF6C63FF) : Colors.red,
      ));
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({required this.icon, required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c),
      title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade700),
      onTap: onTap,
    );
  }
}
