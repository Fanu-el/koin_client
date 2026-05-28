import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/transaction_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/error_view.dart';
import '../../widgets/notifications_action.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: const [NotificationsAction()],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_transactions',
        onPressed: () => context.push(AppRoutes.addTransaction),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TransactionList(type: null),
          _TransactionList(type: 'INCOME'),
          _TransactionList(type: 'EXPENSE'),
        ],
      ),
    );
  }
}

class _TransactionList extends StatefulWidget {
  final String? type;

  const _TransactionList({this.type});

  @override
  State<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<_TransactionList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load(
            type: widget.type,
            refresh: true,
          );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().load(type: widget.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.loadingFor(widget.type) &&
            provider.transactionsFor(widget.type).isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorFor(widget.type) != null &&
            provider.transactionsFor(widget.type).isEmpty) {
          return ErrorView(
            message: provider.errorFor(widget.type)!,
            onRetry: () =>
                provider.load(type: widget.type, refresh: true),
          );
        }

        final txs = provider.transactionsFor(widget.type);

        if (txs.isEmpty) {
          return const EmptyView(
            message: 'No transactions yet.\nTap + to add one.',
            icon: Icons.receipt_long_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.load(type: widget.type, refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                txs.length + (provider.hasMoreFor(widget.type) ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == txs.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _TransactionTile(
                transaction: txs[i],
                onDelete: () => _confirmDelete(context, txs[i].id),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<TransactionProvider>();
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Transaction',
      content: 'Are you sure you want to delete this transaction?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      provider.delete(id);
    }
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = AppColors.categoryColor(transaction.category);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _categoryIcon(transaction.category),
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          transaction.description ??
              TransactionCategory.label(transaction.category),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy').format(transaction.date),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}\$${NumberFormat('#,##0.00').format(transaction.amount)}',
              style: TextStyle(
                color: isIncome ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.textHint,
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'FOOD':
        return Icons.restaurant;
      case 'TRANSPORT':
        return Icons.directions_car;
      case 'HOUSING':
        return Icons.home;
      case 'HEALTHCARE':
        return Icons.local_hospital;
      case 'ENTERTAINMENT':
        return Icons.movie;
      case 'SHOPPING':
        return Icons.shopping_bag;
      case 'UTILITIES':
        return Icons.bolt;
      case 'EDUCATION':
        return Icons.school;
      case 'SALARY':
        return Icons.work;
      case 'FREELANCE':
        return Icons.laptop;
      case 'INVESTMENT':
        return Icons.trending_up;
      case 'GIFT':
        return Icons.card_giftcard;
      default:
        return Icons.attach_money;
    }
  }
}
