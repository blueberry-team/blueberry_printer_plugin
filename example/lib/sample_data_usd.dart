import 'package:blueberry_printer/models/order_detail_response.dart';

/// 미국 샘플 주문 데이터 (USD - 소수점 2자리 표시)
OrderDetailResponse getSampleUSDOrder() {
  return OrderDetailResponse(
    orderId: 'order_001_usd',
    orderNumber: 'ORD-2025-003',
    tableNumber: 7,
    tableName: 'Table 7',
    totalPrice: 42.75,
    orderVersion: [
      OrderVersionResponse(
        versionId: 'v1',
        orderBy: 'TABLE',
        versionNumber: 1,
        createdAt: '2025-10-05 14:30:00',
        orderItems: [
          OrderDetailItemResponse(
            menuId: 'menu_201',
            menuName: 'Cheeseburger',
            quantity: 2,
            price: 12.99,
            options: [
              MenuOptionResponse(
                optionMenuItemId: 'opt_201',
                optionMenuItemName: 'Add-ons',
                isRequired: false,
                isMultiple: true,
                selectedItems: [
                  SelectedOptionItemResponse(
                    menuOptionItemId: 'item_201',
                    itemName: 'Extra Cheese',
                    itemPrice: 1.50,
                    quantity: 2,
                  ),
                  SelectedOptionItemResponse(
                    menuOptionItemId: 'item_202',
                    itemName: 'Bacon',
                    itemPrice: 2.25,
                    quantity: 1,
                  ),
                ],
              ),
            ],
          ),
          OrderDetailItemResponse(
            menuId: 'menu_202',
            menuName: 'French Fries',
            quantity: 2,
            price: 4.99,
            options: [],
          ),
        ],
      ),
    ],
  );
}
