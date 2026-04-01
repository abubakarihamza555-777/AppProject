import 'package:flutter/foundation.dart';

mixin ErrorHandlerMixin on ChangeNotifier {
  String? _error;

  String? get error => _error;
  bool get hasError => _error != null && _error!.trim().isNotEmpty;

  @protected
  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  @protected
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
