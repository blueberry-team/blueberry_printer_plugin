import 'package:blueberry_printer/models/order_history_total_response.dart';

/// 미국 샘플 누적 주문 데이터 (USD - 소수점 2자리 표시)
OrderHistoryTotalResponse getSampleUSDOrder() {
  return OrderHistoryTotalResponse(
    orderId: 'order_001_usd',
    totalPrice: 70.16, // Menu + Options Total
    orderMenus: [
      // Menu 1: Cheeseburger
      OrderMenu(
        menuId: 'menu_201',
        menuName: 'Cheeseburger',
        quantity: 3,
        price: 38.97, // Base price 12.99×3, options separate
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'opt_201',
            menuOptionItemName: 'Add-ons',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_201',
                menuOptionItemDetailName: 'Extra Cheese',
                menuOptionItemDetailPrice: 1.50,
                menuOptionItemDetailQuantity: 2,
              ),
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_202',
                menuOptionItemDetailName: 'Bacon',
                menuOptionItemDetailPrice: 2.25,
                menuOptionItemDetailQuantity: 1,
              ),
            ],
          ),
        ],
      ),
      // Menu 2: French Fries
      OrderMenu(
        menuId: 'menu_202',
        menuName: 'French Fries',
        quantity: 4,
        price: 19.96, // Base price 4.99×4, no options
        menuOptionItems: [],
      ),
      // Menu 3: Coke
      OrderMenu(
        menuId: 'menu_203',
        menuName: 'Coke (Large)',
        quantity: 2,
        price: 5.98, // Base price 2.99×2, option free
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'opt_202',
            menuOptionItemName: 'Ice',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_203',
                menuOptionItemDetailName: 'No Ice',
                menuOptionItemDetailPrice: 0.0,
                menuOptionItemDetailQuantity: 1,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
