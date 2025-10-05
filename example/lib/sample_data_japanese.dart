import 'package:blueberry_printer/models/order_detail_response.dart';

/// 일본 샘플 주문 데이터 (JPY - 정수 표시)
OrderDetailResponse getSampleJapaneseOrder() {
  return OrderDetailResponse(
    orderId: 'order_001_jpn',
    orderNumber: 'ORD-2025-002',
    tableNumber: 3,
    tableName: 'テーブル 3',
    totalPrice: 3250.0,
    orderVersion: [
      OrderVersionResponse(
        versionId: 'v1',
        orderBy: 'TABLE',
        versionNumber: 1,
        createdAt: '2025-10-05 13:15:00',
        orderItems: [
          OrderDetailItemResponse(
            menuId: 'menu_101',
            menuName: 'ラーメン',
            quantity: 2,
            price: 1200.0,
            options: [
              MenuOptionResponse(
                optionMenuItemId: 'opt_101',
                optionMenuItemName: 'トッピング',
                isRequired: false,
                isMultiple: true,
                selectedItems: [
                  SelectedOptionItemResponse(
                    menuOptionItemId: 'item_101',
                    itemName: 'チャーシュー追加',
                    itemPrice: 300.0,
                    quantity: 1,
                  ),
                ],
              ),
            ],
          ),
          OrderDetailItemResponse(
            menuId: 'menu_102',
            menuName: '餃子',
            quantity: 1,
            price: 550.0,
            options: [],
          ),
        ],
      ),
    ],
  );
}
