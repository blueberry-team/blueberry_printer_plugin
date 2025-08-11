/// 주문 상세 응답
class OrderDetailResponse {
  /// 생성자
  const OrderDetailResponse({
    required this.orderId,
    required this.orderNumber,
    required this.tableNumber,
    required this.tableName,
    required this.totalPrice,
    required this.orderVersion,
  });

  /// 주문 ID
  final String orderId;

  /// 주문 번호
  final String orderNumber;

  /// 테이블 번호
  final int tableNumber;

  /// 테이블 이름
  final String tableName;

  /// 총 가격
  final int totalPrice;

  /// 주문 버전들 (영수증)
  final List<OrderVersionResponse> orderVersion;

  /// JSON에서 생성
  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailResponse(
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      tableNumber: json['tableNumber'] as int,
      tableName: json['tableName'] as String,
      totalPrice: json['totalPrice'] as int,
      orderVersion: (json['orderVersion'] as List<dynamic>)
          .map((e) => OrderVersionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'tableNumber': tableNumber,
      'tableName': tableName,
      'totalPrice': totalPrice,
      'orderVersion': orderVersion.map((e) => e.toJson()).toList(),
    };
  }

  /// API 응답에서 생성
  static OrderDetailResponse? fromApiResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null || data['order'] == null || data['order'] is List) {
      return null;
    }

    final orderJson = data['order'] as Map<String, dynamic>;

    // 재귀적으로 null 리스트를 빈 리스트로 변환
    void convertNullListsToEmpty(Map<String, dynamic> json) {
      if (json['orderVersion'] == null) {
        json['orderVersion'] = [];
      }
      for (final version in (json['orderVersion'] as List)) {
        final versionMap = version as Map<String, dynamic>;
        if (versionMap['orderItems'] == null) {
          versionMap['orderItems'] = [];
        }
        for (final item in (versionMap['orderItems'] as List)) {
          final itemMap = item as Map<String, dynamic>;
          if (itemMap['options'] == null) {
            itemMap['options'] = [];
          }
          for (final option in (itemMap['options'] as List)) {
            final optionMap = option as Map<String, dynamic>;
            if (optionMap['selectedItems'] == null) {
              optionMap['selectedItems'] = [];
            }
          }
        }
      }
    }

    convertNullListsToEmpty(orderJson);

    return OrderDetailResponse.fromJson(orderJson);
  }
}

/// 주문 버전 응답 (영수증)
class OrderVersionResponse {
  /// 생성자
  const OrderVersionResponse({
    required this.versionId,
    required this.orderBy,
    required this.versionNumber,
    required this.createdAt,
    required this.orderItems,
  });

  /// 버전 ID
  final String versionId;

  /// 주문자 (TABLE, CALL 등)
  final String orderBy;

  /// 버전 번호
  final int versionNumber;

  /// 생성 시간
  final String createdAt;

  /// 주문 아이템들
  final List<OrderDetailItemResponse> orderItems;

  /// JSON에서 생성
  factory OrderVersionResponse.fromJson(Map<String, dynamic> json) {
    return OrderVersionResponse(
      versionId: json['versionId'] as String,
      orderBy: json['orderBy'] as String,
      versionNumber: json['versionNumber'] as int,
      createdAt: json['createdAt'] as String,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((e) => OrderDetailItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'versionId': versionId,
      'orderBy': orderBy,
      'versionNumber': versionNumber,
      'createdAt': createdAt,
      'orderItems': orderItems.map((e) => e.toJson()).toList(),
    };
  }
}

/// 주문 상세 아이템 응답
class OrderDetailItemResponse {
  /// 생성자
  const OrderDetailItemResponse({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.price,
    required this.options,
  });

  /// 메뉴 ID
  final String menuId;

  /// 메뉴 이름
  final String menuName;

  /// 수량
  final int quantity;

  /// 가격
  final int price;

  /// 옵션들
  final List<MenuOptionResponse> options;

  /// JSON에서 생성
  factory OrderDetailItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailItemResponse(
      menuId: json['menuId'] as String,
      menuName: json['menuName'] as String,
      quantity: json['quantity'] as int,
      price: json['price'] as int,
      options: (json['options'] as List<dynamic>)
          .map((e) => MenuOptionResponse.fromJson(e as Map<String, dynamic>))
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
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

/// 메뉴 옵션 응답
class MenuOptionResponse {
  /// 생성자
  const MenuOptionResponse({
    required this.optionMenuItemId,
    required this.optionMenuItemName,
    this.isRequired,
    this.isMultiple,
    required this.selectedItems,
  });

  /// 옵션 메뉴 아이템 ID
  final String optionMenuItemId;

  /// 옵션 메뉴 아이템 이름
  final String optionMenuItemName;

  /// 필수 선택 여부
  final bool? isRequired;

  /// 복수 선택 여부
  final bool? isMultiple;

  /// 선택된 아이템들
  final List<SelectedOptionItemResponse> selectedItems;

  /// JSON에서 생성
  factory MenuOptionResponse.fromJson(Map<String, dynamic> json) {
    return MenuOptionResponse(
      optionMenuItemId: json['optionMenuItemId'] as String,
      optionMenuItemName: json['optionMenuItemName'] as String,
      isRequired: json['isRequired'] as bool?,
      isMultiple: json['isMultiple'] as bool?,
      selectedItems: (json['selectedItems'] as List<dynamic>)
          .map((e) => SelectedOptionItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'optionMenuItemId': optionMenuItemId,
      'optionMenuItemName': optionMenuItemName,
      'isRequired': isRequired,
      'isMultiple': isMultiple,
      'selectedItems': selectedItems.map((e) => e.toJson()).toList(),
    };
  }

  /// 리스트 전체 json → MenuOptionResponse List
  static List<MenuOptionResponse> fromApiResponse(dynamic res) {
    if (res is List) {
      return res.map((e) => MenuOptionResponse.fromJson(e)).toList();
    }

    if (res is Map<String, dynamic> && res['options'] is List) {
      return (res['options'] as List)
          .map((e) => MenuOptionResponse.fromJson(e))
          .toList();
    }
    return [];
  }
}

/// 선택된 옵션 아이템 응답
class SelectedOptionItemResponse {
  /// 생성자
  const SelectedOptionItemResponse({
    required this.menuOptionItemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
  });

  /// 메뉴 옵션 아이템 ID
  final String menuOptionItemId;

  /// 아이템 이름
  final String itemName;

  /// 아이템 가격
  final int itemPrice;

  /// 수량
  final int quantity;

  /// JSON에서 생성
  factory SelectedOptionItemResponse.fromJson(Map<String, dynamic> json) {
    return SelectedOptionItemResponse(
      menuOptionItemId: json['menuOptionItemId'] as String,
      itemName: json['itemName'] as String,
      itemPrice: json['itemPrice'] as int,
      quantity: json['quantity'] as int,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'menuOptionItemId': menuOptionItemId,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'quantity': quantity,
    };
  }
}
