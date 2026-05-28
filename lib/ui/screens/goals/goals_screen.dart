import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../../providers/savings_goal_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_notifications.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_notifications.dart';
import '../../widgets/error_view.dart';
import '../../widgets/notifications_action.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingsGoalProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: const [NotificationsAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_goals',
        onPressed: () => _showGoalSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SavingsGoalProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.goals.isEmpty) {
            return const AppLoader();
          }
          if (provider.error != null && provider.goals.isEmpty) {
            return ErrorView(
              message: provider.error!,
              onRetry: provider.load,
            );
          }
          if (provider.goals.isEmpty) {
            return EmptyView(
              message: 'No savings goals yet.\nSet one to start saving.',
              icon: Icons.flag_outlined,
              actionLabel: 'Create Goal',
              onAction: () => _showGoalSheet(context),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final goal = provider.goals[i];
                return _GoalCard(
                  goal: goal,
                  onEdit: () => _showGoalSheet(context, goal: goal),
                  onAddFunds: () => _showAddFundsSheet(context, goal),
                  onDelete: () => _confirmDelete(context, goal.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<SavingsGoalProvider>();
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Goal',
      content: 'Remove this savings goal?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      provider.delete(id);
    }
  }

  void _showGoalSheet(BuildContext context, {SavingsGoalModel? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GoalFormSheet(goal: goal),
    );
  }

  void _showAddFundsSheet(BuildContext context, SavingsGoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddFundsSheet(goal: goal),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback onEdit;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onAddFunds,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal.progressPercent;
    final isCompleted = goal.status == SavingsGoalStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (goal.targetDate != null)
                        Text(
                          'Target: ${DateFormat('MMM d, yyyy').format(goal.targetDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.income,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${NumberFormat('#,##0.00').format(goal.currentAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'of \$${NumberFormat('#,##0.00').format(goal.targetAmount)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  isCompleted ? AppColors.income : AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pct * 100).toStringAsFixed(0)}% saved',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${NumberFormat('#,##0.00').format(goal.remaining)} to go',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddFunds,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Funds'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  final SavingsGoalModel? goal;

  const _GoalFormSheet({this.goal});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      final g = widget.goal!;
      _nameCtrl.text = g.name;
      _targetCtrl.text = g.targetAmount.toStringAsFixed(2);
      _currentCtrl.text = g.currentAmount.toStringAsFixed(2);
      _descCtrl.text = g.description ?? '';
      _targetDate = g.targetDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', ''));
    final current = double.tryParse(_currentCtrl.text.replaceAll(',', '')) ?? 0;

    if (name.isEmpty || target == null || target <= 0) {
      showAppSnackBar(context, 'Name and target amount are required');
      return;
    }

    final provider = context.read<SavingsGoalProvider>();
    bool ok;
    if (widget.goal != null) {
      ok = await provider.update(
        widget.goal!.id,
        name: name,
        targetAmount: target,
        currentAmount: current,
        targetDate: _targetDate,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
    } else {
      ok = await provider.create(
        name: name,
        targetAmount: target,
        currentAmount: current,
        targetDate: _targetDate,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
    }

    if (ok && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      showErrorSnackBar(context, provider.error ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal != null ? 'Edit Goal' : 'New Savings Goal',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Goal Name'),
              maxLength: 160,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              decoration: const InputDecoration(
                labelText: 'Current Amount',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _targetDate != null
                          ? 'Target: ${DateFormat('MMM d, yyyy').format(_targetDate!)}'
                          : 'Set target date (optional)',
                      style: TextStyle(
                        color: _targetDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.goal != null ? 'Update Goal' : 'Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFundsSheet extends StatefulWidget {
  final SavingsGoalModel goal;

  const _AddFundsSheet({required this.goal});

  @override
  State<_AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<_AddFundsSheet> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final add = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (add == null || add <= 0) {
      showAppSnackBar(context, 'Enter a valid amount');
      return;
    }
    final newAmount = widget.goal.currentAmount + add;
    final provider = context.read<SavingsGoalProvider>();
    final ok = await provider.update(
      widget.goal.id,
      currentAmount: newAmount,
      status: newAmount >= widget.goal.targetAmount
          ? SavingsGoalStatus.completed
          : null,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Funds to "${widget.goal.name}"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: \$${NumberFormat('#,##0.00').format(widget.goal.currentAmount)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount to Add',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Add Funds'),
            ),
          ),
        ],
      ),
    );
  }
}
