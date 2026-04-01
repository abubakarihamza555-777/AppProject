import 'package:flutter/foundation.dart';

mixin LoadingMixin on ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  @protected
  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
