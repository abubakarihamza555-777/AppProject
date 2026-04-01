enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  completed,
}

extension OrderStatusX on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      default:
        return toString().split('.').last;
    }
  }

  static OrderStatus? fromName(String name) {
    switch (name) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'completed':
        return OrderStatus.completed;
      default:
        return null;
    }
  }
}
