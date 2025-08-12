import 'package:blueberry_printer/models/order_history_total_response.dart';

/// 전체 주문 영수증을 위한 샘플 데이터를 생성합니다.
/// iOS와의 호환성을 위해 toJson() 메소드도 포함합니다.
OrderHistoryTotalResponse getSampleTotalOrderData() {
  return OrderHistoryTotalResponse(
    orderId: 'ORDER_001',
    totalPrice: 45000, // 누적 총 금액
    orderMenus: [
      // 아메리카노 (메뉴 1)
      OrderMenu(
        menuId: 'MENU_001',
        menuName: '아메리카노',
        quantity: 2,
        price: 4500,
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'OPT_001',
            menuOptionItemName: '사이즈',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'SIZE_L',
                menuOptionItemDetailName: '라지',
                menuOptionItemDetailPrice: 500,
                menuOptionItemDetailQuantity: 2,
              ),
            ],
          ),
        ],
      ),
      // 카페라떼 (메뉴 2)
      OrderMenu(
        menuId: 'MENU_002',
        menuName: '카페라떼',
        quantity: 1,
        price: 5000,
        menuOptionItems: [],
      ),
      // 단호박 케이크 (메뉴 3)
      OrderMenu(
        menuId: 'MENU_003',
        menuName: '단호박 케이크',
        quantity: 1,
        price: 6500,
        menuOptionItems: [],
      ),
      // 아이스 티 (메뉴 4)
      OrderMenu(
        menuId: 'MENU_004',
        menuName: '아이스 티',
        quantity: 3,
        price: 3000,
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'OPT_002',
            menuOptionItemName: '시럽',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'SYRUP_VANILLA',
                menuOptionItemDetailName: '바닐라 시럽',
                menuOptionItemDetailPrice: 500,
                menuOptionItemDetailQuantity: 2,
              ),
              SelectedOptionItem(
                menuOptionItemDetailId: 'SYRUP_CARAMEL',
                menuOptionItemDetailName: '카라멜 시럽',
                menuOptionItemDetailPrice: 500,
                menuOptionItemDetailQuantity: 1,
              ),
            ],
          ),
        ],
      ),
      // 크로와상 (메뉴 5)
      OrderMenu(
        menuId: 'MENU_005',
        menuName: '크로와상',
        quantity: 2,
        price: 4000,
        menuOptionItems: [],
      ),
    ],
  );
}
