import 'package:blueberry_printer/models/order_history_total_response.dart';

/// 한국 샘플 누적 주문 데이터 (KRW - 정수 표시)
OrderHistoryTotalResponse getSampleKoreanOrder() {
  return OrderHistoryTotalResponse(
    orderId: 'order_001_kor',
    totalPrice: 70500.0, // 메뉴 + 옵션 총합
    orderMenus: [
      // 메뉴 1: 김치찌개
      OrderMenu(
        menuId: 'menu_001',
        menuName: '김치찌개',
        quantity: 3,
        price: 27000.0, // 기본가 9000×3, 옵션 별도
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'opt_001',
            menuOptionItemName: '추가 토핑',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_001',
                menuOptionItemDetailName: '치즈 추가',
                menuOptionItemDetailPrice: 1000.0,
                menuOptionItemDetailQuantity: 2,
              ),
            ],
          ),
        ],
      ),
      // 메뉴 2: 불고기
      OrderMenu(
        menuId: 'menu_002',
        menuName: '불고기',
        quantity: 2,
        price: 30000.0, // 기본가 15000×2, 옵션 별도
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'opt_002',
            menuOptionItemName: '사이드',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_002',
                menuOptionItemDetailName: '공기밥',
                menuOptionItemDetailPrice: 1500.0,
                menuOptionItemDetailQuantity: 2,
              ),
            ],
          ),
        ],
      ),
      // 메뉴 3: 된장찌개
      OrderMenu(
        menuId: 'menu_003',
        menuName: '된장찌개',
        quantity: 1,
        price: 8500.0,
        menuOptionItems: [],
      ),
    ],
  );
}
