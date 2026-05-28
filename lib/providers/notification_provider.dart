import 'package:flutter/foundation.dart';
import '../core/utils/error_utils.dart';
import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  List<NotificationModel> _items = [];
  bool _loading = false;
  String? _error;

  NotificationProvider(this._service);

  List<NotificationModel> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.listNotifications();
    } catch (e) {
      _error = formatError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    try {
      final updated = await _service.markRead(id);
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _items[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
    }
  }
}
