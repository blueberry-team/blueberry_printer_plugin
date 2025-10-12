import 'package:blueberry_printer/models/order_history_total_response.dart';

/// 일본 샘플 누적 주문 데이터 (JPY - 정수 표시)
OrderHistoryTotalResponse getSampleJapaneseOrder() {
  return OrderHistoryTotalResponse(
    orderId: 'order_001_jpn',
    totalPrice: 6200.0, // メニュー + オプション 合計
    orderMenus: [
      // メニュー 1: ラーメン
      OrderMenu(
        menuId: 'menu_101',
        menuName: 'ラーメン',
        quantity: 3,
        price: 3600.0, // 基本価格 1200×3, オプション別途
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'opt_101',
            menuOptionItemName: 'トッピング',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_101',
                menuOptionItemDetailName: 'チャーシュー追加',
                menuOptionItemDetailPrice: 300.0,
                menuOptionItemDetailQuantity: 2,
              ),
            ],
          ),
        ],
      ),
      // メニュー 2: 餃子
      OrderMenu(
        menuId: 'menu_102',
        menuName: '餃子',
        quantity: 2,
        price: 1100.0, // 基本価格 550×2, オプションなし
        menuOptionItems: [],
      ),
      // メニュー 3: チャーハン
      OrderMenu(
        menuId: 'menu_103',
        menuName: 'チャーハン',
        quantity: 1,
        price: 900.0,
        menuOptionItems: [
          MenuOptionItem(
            menuOptionItemId: 'opt_102',
            menuOptionItemName: '辛さ',
            selectedItems: [
              SelectedOptionItem(
                menuOptionItemDetailId: 'item_102',
                menuOptionItemDetailName: '激辛',
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
