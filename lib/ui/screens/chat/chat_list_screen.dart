import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/chat_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_notifications.dart';
import '../../widgets/error_view.dart';
import '../../widgets/notifications_action.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
        actions: [
          const NotificationsAction(),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: () => _startNewChat(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.loadingSessions && provider.sessions.isEmpty) {
            return const AppLoader();
          }
          if (provider.sessions.isEmpty) {
            return EmptyView(
              message:
                  'No conversations yet.\nAsk Koin anything about your finances.',
              icon: Icons.chat_bubble_outline,
              actionLabel: 'Start a Chat',
              onAction: () => _startNewChat(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadSessions(force: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final session = provider.sessions[i];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      session.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatDate(session.updatedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') {
                          _renameDialog(context, session.id, session.title);
                        }
                        if (v == 'delete') {
                          _confirmDelete(context, session.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'rename', child: Text('Rename')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await context.read<ChatProvider>().openSession(session);
                      if (context.mounted) {
                        context.push(
                          '${AppRoutes.chat}/${session.id}',
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _startNewChat(BuildContext context) async {
    final provider = context.read<ChatProvider>();
    final session = await provider.createSession();
    if (session != null && context.mounted) {
      await provider.openSession(session);
      if (context.mounted) {
        context.push('${AppRoutes.chat}/${session.id}');
      }
    }
  }

  Future<void> _renameDialog(
      BuildContext context, String id, String currentTitle) async {
    final newTitle = await showTextInputDialog(
      context,
      title: 'Rename Chat',
      hintText: 'Chat title',
      initialValue: currentTitle,
    );
    if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
      final success = await context.read<ChatProvider>().renameSession(id, newTitle);
      if (!success && context.mounted) {
        showErrorSnackBar(context, context.read<ChatProvider>().error ?? 'Failed to rename chat');
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<ChatProvider>();
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Chat',
      content: 'Delete this conversation?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      provider.deleteSession(id);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
