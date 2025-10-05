import 'package:blueberry_printer/models/order_detail_response.dart';

/// 한국 샘플 주문 데이터 (KRW - 정수 표시)
OrderDetailResponse getSampleKoreanOrder() {
  return OrderDetailResponse(
    orderId: 'order_001_kor',
    orderNumber: 'ORD-2025-001',
    tableNumber: 5,
    tableName: '테이블 5',
    totalPrice: 28500.0,
    orderVersion: [
      OrderVersionResponse(
        versionId: 'v1',
        orderBy: 'TABLE',
        versionNumber: 1,
        createdAt: '2025-10-05 12:30:00',
        orderItems: [
          OrderDetailItemResponse(
            menuId: 'menu_001',
            menuName: '김치찌개',
            quantity: 2,
            price: 9000.0,
            options: [
              MenuOptionResponse(
                optionMenuItemId: 'opt_001',
                optionMenuItemName: '추가 토핑',
                isRequired: false,
                isMultiple: true,
                selectedItems: [
                  SelectedOptionItemResponse(
                    menuOptionItemId: 'item_001',
                    itemName: '치즈 추가',
                    itemPrice: 1000.0,
                    quantity: 1,
                  ),
                ],
              ),
            ],
          ),
          OrderDetailItemResponse(
            menuId: 'menu_002',
            menuName: '불고기',
            quantity: 1,
            price: 15000.0,
            options: [
              MenuOptionResponse(
                optionMenuItemId: 'opt_002',
                optionMenuItemName: '사이드',
                isRequired: false,
                isMultiple: false,
                selectedItems: [
                  SelectedOptionItemResponse(
                    menuOptionItemId: 'item_002',
                    itemName: '공기밥',
                    itemPrice: 1500.0,
                    quantity: 2,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
