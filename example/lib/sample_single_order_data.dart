import 'package:blueberry_printer/models/order_detail_response.dart';

/// 단일 주문 영수증을 위한 샘플 데이터를 생성합니다.
OrderDetailResponse getSampleSingleOrderData() {
  return OrderDetailResponse(
    orderId: 'ORDER_001',
    orderNumber: 'ORD-2024-001',
    tableNumber: 5,
    tableName: '테이블 5',
    totalPrice: 22500,
    orderVersion: [
      OrderVersionResponse(
        versionId: 'V001',
        orderBy: 'TABLE',
        versionNumber: 1,
        createdAt: '2024-08-11 23:30:00',
        orderItems: [
          OrderDetailItemResponse(
            menuId: 'MENU_001',
            menuName: '아메리카노 (ICE)',
            quantity: 2,
            price: 9000, // 4500 * 2
            options: [
              MenuOptionResponse(
                optionMenuItemId: 'OPT_001',
                optionMenuItemName: '시럽 추가',
                isRequired: false,
                isMultiple: true,
                selectedItems: [
                  SelectedOptionItemResponse(
                    menuOptionItemId: 'ITEM_001',
                    itemName: '바닐라 시럽',
                    itemPrice: 500,
                    quantity: 1,
                  ),
                ],
              ),
            ],
          ),
          OrderDetailItemResponse(
            menuId: 'MENU_002',
            menuName: '카페라떼 (HOT)',
            quantity: 1,
            price: 5000,
            options: [],
          ),
          OrderDetailItemResponse(
            menuId: 'MENU_003',
            menuName: '블루베리 머핀',
            quantity: 2,
            price: 7000, // 3500 * 2
            options: [],
          ),
          OrderDetailItemResponse(
            menuId: 'MENU_004',
            menuName: '에스프레소 이중샷',
            quantity: 1,
            price: 1000,
            options: [],
          ),
        ],
      ),
    ],
  );
}
