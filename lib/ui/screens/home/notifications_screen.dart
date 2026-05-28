import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.items.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.separated(
                  itemCount: prov.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final n = prov.items[i];
                    return ListTile(
                      leading: Icon(
                        n.type == 'WARNING' ? Icons.warning_amber_outlined : Icons.notifications_outlined,
                        color: n.type == 'WARNING' ? AppColors.warning : AppColors.primary,
                      ),
                      title: Text(n.title),
                      subtitle: Text(n.body),
                      trailing: n.read ? null : TextButton(
                        onPressed: () async => await context.read<NotificationProvider>().markRead(n.id),
                        child: const Text('Mark read'),
                      ),
                    );
                  },
                ),
    );
  }
}
