import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/budget_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_notifications.dart';
import '../../widgets/error_view.dart';
import '../../widgets/notifications_action.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: const [NotificationsAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_budgets',
        onPressed: () => _showAddBudgetSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.budgetStatus.isEmpty) {
            return const AppLoader();
          }
          if (provider.error != null && provider.budgetStatus.isEmpty) {
            return ErrorView(
              message: provider.error!,
              onRetry: provider.load,
            );
          }
          if (provider.budgetStatus.isEmpty) {
            return EmptyView(
              message: 'No budgets set.\nAdd one to track your spending.',
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: 'Add Budget',
              onAction: () => _showAddBudgetSheet(context),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.budgetStatus.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = provider.budgetStatus[i];
                return _BudgetCard(
                  item: item,
                  onEdit: () => _showEditBudgetSheet(context, item.budget),
                  onDelete: () => _confirmDelete(context, item.budget.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<BudgetProvider>();
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Budget',
      content: 'Remove this budget?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      provider.delete(id);
    }
  }

  void _showAddBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _BudgetFormSheet(),
    );
  }

  void _showEditBudgetSheet(BuildContext context, BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BudgetFormSheet(budget: budget),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetStatusItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (item.percentUsed / 100).clamp(0.0, 1.0);
    final color = pct > 0.9
        ? AppColors.error
        : pct > 0.7
            ? AppColors.warning
            : AppColors.income;
    final catColor = AppColors.categoryColor(item.budget.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.category_outlined, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(item.budget.category),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        item.budget.period == BudgetPeriod.monthly
                            ? 'Monthly'
                            : 'Weekly',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                  '\$${NumberFormat('#,##0.00').format(item.spent)} spent',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'of \$${NumberFormat('#,##0.00').format(item.budget.amountLimit)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.percentUsed.toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${NumberFormat('#,##0.00').format(item.remaining)} remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(String cat) =>
      cat[0] + cat.substring(1).toLowerCase().replaceAll('_', ' ');
}

class _BudgetFormSheet extends StatefulWidget {
  final BudgetModel? budget;

  const _BudgetFormSheet({this.budget});

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _amountCtrl = TextEditingController();
  String _category = TransactionCategory.food;
  String _period = BudgetPeriod.monthly;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _category = widget.budget!.category;
      _period = widget.budget!.period;
      _amountCtrl.text = widget.budget!.amountLimit.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, 'Enter a valid amount');
      return;
    }

    final provider = context.read<BudgetProvider>();
    bool ok;
    if (widget.budget != null) {
      ok = await provider.update(widget.budget!.id, amount);
    } else {
      ok = await provider.create(
        category: _category,
        period: _period,
        amountLimit: amount,
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
    final isEdit = widget.budget != null;
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
            isEdit ? 'Edit Budget' : 'New Budget',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          if (!isEdit) ...[
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Category',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  items: TransactionCategory.expenseCategories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(TransactionCategory.label(c)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Period',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _period,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                  ],
                  onChanged: (v) => setState(() => _period = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Limit Amount',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Text(isEdit ? 'Update Budget' : 'Create Budget'),
            ),
          ),
        ],
      ),
    );
  }
}
