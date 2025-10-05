/// 주문 내역 총 가격 응답
class OrderHistoryTotalResponse {
  /// 생성자
  const OrderHistoryTotalResponse({
    required this.orderId,
    required this.totalPrice,
    required this.orderMenus,
  });

  /// 주문 ID
  final String orderId;

  /// 총 가격
  final double totalPrice;

  /// 주문 메뉴 목록
  final List<OrderMenu> orderMenus;

  /// JSON에서 생성
  factory OrderHistoryTotalResponse.fromJson(Map<String, dynamic> json) {
    return OrderHistoryTotalResponse(
      orderId: json['orderId'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      orderMenus: (json['orderMenus'] as List<dynamic>)
          .map((e) => OrderMenu.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'totalPrice': totalPrice,
      'orderMenus': orderMenus.map((e) => e.toJson()).toList(),
    };
  }

  /// API 응답에서 생성
  static OrderHistoryTotalResponse? fromApiResponse(Map<String, dynamic> response) {
    final data = response['data']?['order'];
    if (data == null || data is! Map<String, dynamic>) {
      return null;
    }

    /// null 리스트를 빈 리스트로 변환
    void convertNullListsToEmpty(Map<String, dynamic> map) {
      if (map['orderMenus'] == null) {
        map['orderMenus'] = [];
      }
      for (final menu in (map['orderMenus'] as List)) {
        final menuMap = menu as Map<String, dynamic>;
        if (menuMap['menuOptionItems'] == null) {
          menuMap['menuOptionItems'] = [];
        }
        for (final option in (menuMap['menuOptionItems'] as List)) {
          final optionMap = option as Map<String, dynamic>;
          if (optionMap['selectedItems'] == null) {
            optionMap['selectedItems'] = [];
          }
        }
      }
    }

    convertNullListsToEmpty(data);
    return OrderHistoryTotalResponse.fromJson(data);
  }
}

/// 주문 메뉴 응답
class OrderMenu {
  /// 생성자
  const OrderMenu({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.price,
    required this.menuOptionItems,
  });

  /// 메뉴 ID
  final String menuId;
  
  /// 메뉴 이름
  final String menuName;
  
  /// 수량
  final int quantity;
  
  /// 가격
  final double price;
  
  /// 메뉴 옵션 아이템 목록
  final List<MenuOptionItem> menuOptionItems;

  /// JSON에서 생성
  factory OrderMenu.fromJson(Map<String, dynamic> json) {
    return OrderMenu(
      menuId: json['menuId'] as String,
      menuName: json['menuName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      menuOptionItems: (json['menuOptionItems'] as List<dynamic>)
          .map((e) => MenuOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'menuName': menuName,
      'quantity': quantity,
      'price': price,
      'menuOptionItems': menuOptionItems.map((e) => e.toJson()).toList(),
    };
  }
}

/// 메뉴 옵션 응답
class MenuOptionItem {
  /// 생성자
  const MenuOptionItem({
    required this.menuOptionItemId,
    required this.menuOptionItemName,
    required this.selectedItems,
  });

  /// 메뉴 옵션 아이템 ID
  final String menuOptionItemId;
  
  /// 메뉴 옵션 아이템 이름
  final String menuOptionItemName;
  
  /// 선택된 옵션 아이템 목록
  final List<SelectedOptionItem> selectedItems;

  /// JSON에서 생성
  factory MenuOptionItem.fromJson(Map<String, dynamic> json) {
    return MenuOptionItem(
      menuOptionItemId: json['menuOptionItemId'] as String,
      menuOptionItemName: json['menuOptionItemName'] as String,
      selectedItems: (json['selectedItems'] as List<dynamic>)
          .map((e) => SelectedOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'menuOptionItemId': menuOptionItemId,
      'menuOptionItemName': menuOptionItemName,
      'selectedItems': selectedItems.map((e) => e.toJson()).toList(),
    };
  }
}

/// 선택된 옵션 응답
class SelectedOptionItem {
  /// 생성자
  const SelectedOptionItem({
    required this.menuOptionItemDetailId,
    required this.menuOptionItemDetailName,
    required this.menuOptionItemDetailPrice,
    required this.menuOptionItemDetailQuantity,
  });

  /// 메뉴 옵션 아이템 상세 ID
  final String menuOptionItemDetailId;
  
  /// 메뉴 옵션 아이템 상세 이름
  final String menuOptionItemDetailName;
  
  /// 메뉴 옵션 아이템 상세 가격
  final double menuOptionItemDetailPrice;
  
  /// 메뉴 옵션 아이템 상세 수량
  final int menuOptionItemDetailQuantity;

  /// JSON에서 생성
  factory SelectedOptionItem.fromJson(Map<String, dynamic> json) {
    return SelectedOptionItem(
      menuOptionItemDetailId: json['menuOptionItemDetailId'] as String,
      menuOptionItemDetailName: json['menuOptionItemDetailName'] as String,
      menuOptionItemDetailPrice: (json['menuOptionItemDetailPrice'] as num).toDouble(),
      menuOptionItemDetailQuantity: json['menuOptionItemDetailQuantity'] as int,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'menuOptionItemDetailId': menuOptionItemDetailId,
      'menuOptionItemDetailName': menuOptionItemDetailName,
      'menuOptionItemDetailPrice': menuOptionItemDetailPrice,
      'menuOptionItemDetailQuantity': menuOptionItemDetailQuantity,
    };
  }
}
