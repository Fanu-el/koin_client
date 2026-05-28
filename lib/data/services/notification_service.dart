import '../services/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _api;

  NotificationService(this._api);

  Future<List<NotificationModel>> listNotifications() async {
    final data = await _api.get('/notifications');
    return (data as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationModel> markRead(String id) async {
    final data = await _api.patch('/notifications/$id/read');
    return NotificationModel.fromJson(data as Map<String, dynamic>);
  }
}
