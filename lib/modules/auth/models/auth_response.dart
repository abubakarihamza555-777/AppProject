class AuthResponse {
  final bool success;
  final String? message;
  final String? userId;
  final String? token;
  
  AuthResponse({
    required this.success,
    this.message,
    this.userId,
    this.token,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      userId: json['user_id'] as String?,
      token: json['token'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user_id': userId,
      'token': token,
    };
  }
} 
