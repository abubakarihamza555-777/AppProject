extension StringExtensions on String {
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }
  
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^[0-9]{10,12}$');
    return phoneRegex.hasMatch(this);
  }
  
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
  
  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  String get initials {
    if (isEmpty) return '';
    final parts = split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }
}
