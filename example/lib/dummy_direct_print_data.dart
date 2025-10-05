import 'package:blueberry_printer/models/order_detail_response.dart';
import 'package:blueberry_printer/models/order_history_total_response.dart';

/// 직접 출력 방식 테스트를 위한 더미 데이터
class DummyDirectPrintData {

  /// 단일 주문 더미 데이터 (Direct Print 방식 테스트용)
  static OrderDetailResponse getSingleOrderData() {
    return OrderDetailResponse(
      orderId: 'DIRECT_ORDER_001',
      orderNumber: 'DIRECT-2024-1005',
      tableNumber: 7,
      tableName: '테이블 7번',
      totalPrice: 35500,
      orderVersion: [
        OrderVersionResponse(
          versionId: 'V_DIRECT_001',
          orderBy: 'TABLE',
          versionNumber: 1,
          createdAt: '2024-10-05 15:45:00',
          orderItems: [
            // 메뉴 1: 카푸치노 (옵션 있음)
            OrderDetailItemResponse(
              menuId: 'MENU_DIRECT_001',
              menuName: '카푸치노 (ICE)',
              quantity: 2,
              price: 5500, // 단가
              options: [
                MenuOptionResponse(
                  optionMenuItemId: 'OPT_DIRECT_001',
                  optionMenuItemName: '추가 샷',
                  isRequired: false,
                  isMultiple: false,
                  selectedItems: [
                    SelectedOptionItemResponse(
                      menuOptionItemId: 'SHOT_EXTRA',
                      itemName: '에스프레소 샷 추가',
                      itemPrice: 500,
                      quantity: 2, // 각 음료마다 추가
                    ),
                  ],
                ),
                MenuOptionResponse(
                  optionMenuItemId: 'OPT_DIRECT_002',
                  optionMenuItemName: '토핑',
                  isRequired: false,
                  isMultiple: true,
                  selectedItems: [
                    SelectedOptionItemResponse(
                      menuOptionItemId: 'TOPPING_CINNAMON',
                      itemName: '시나몬 파우더',
                      itemPrice: 0,
                      quantity: 2,
                    ),
                  ],
                ),
              ],
            ),
            // 메뉴 2: 모카라떼 (옵션 있음)
            OrderDetailItemResponse(
              menuId: 'MENU_DIRECT_002',
              menuName: '모카라떼 (HOT)',
              quantity: 1,
              price: 6000,
              options: [
                MenuOptionResponse(
                  optionMenuItemId: 'OPT_DIRECT_003',
                  optionMenuItemName: '휘핑 크림',
                  isRequired: false,
                  isMultiple: false,
                  selectedItems: [
                    SelectedOptionItemResponse(
                      menuOptionItemId: 'WHIPPING_CREAM',
                      itemName: '휘핑 크림 추가',
                      itemPrice: 700,
                      quantity: 1,
                    ),
                  ],
                ),
              ],
            ),
            // 메뉴 3: 티라미수 (옵션 없음)
            OrderDetailItemResponse(
              menuId: 'MENU_DIRECT_003',
              menuName: '티라미수 케이크',
              quantity: 2,
              price: 6500,
              options: [],
            ),
            // 메뉴 4: 샌드위치 (옵션 있음)
            OrderDetailItemResponse(
              menuId: 'MENU_DIRECT_004',
              menuName: '클럽 샌드위치',
              quantity: 1,
              price: 8500,
              options: [
                MenuOptionResponse(
                  optionMenuItemId: 'OPT_DIRECT_004',
                  optionMenuItemName: '빵 선택',
                  isRequired: true,
                  isMultiple: false,
                  selectedItems: [
                    SelectedOptionItemResponse(
                      menuOptionItemId: 'BREAD_WHOLE',
                      itemName: '통밀빵',
                      itemPrice: 500,
                      quantity: 1,
                    ),
                  ],
                ),
              ],
            ),
            // 메뉴 5: 주스 (옵션 없음)
            OrderDetailItemResponse(
              menuId: 'MENU_DIRECT_005',
              menuName: '오렌지 주스',
              quantity: 1,
              price: 4500,
              options: [],
            ),
          ],
        ),
      ],
    );
  }

  /// 전체 주문 더미 데이터 (Direct Print 방식 테스트용)
  static OrderHistoryTotalResponse getTotalOrderData() {
    return OrderHistoryTotalResponse(
      orderId: 'DIRECT_TOTAL_ORDER_001',
      totalPrice: 67500, // 누적 총 금액
      orderMenus: [
        // 메뉴 1: 에스프레소 (누적 3개)
        OrderMenu(
          menuId: 'MENU_TOTAL_001',
          menuName: '에스프레소',
          quantity: 3,
          price: 3500,
          menuOptionItems: [
            MenuOptionItem(
              menuOptionItemId: 'OPT_TOTAL_001',
              menuOptionItemName: '샷 추가',
              selectedItems: [
                SelectedOptionItem(
                  menuOptionItemDetailId: 'SHOT_DOUBLE',
                  menuOptionItemDetailName: '더블샷',
                  menuOptionItemDetailPrice: 1000,
                  menuOptionItemDetailQuantity: 3, // 3개 모두 더블샷
                ),
              ],
            ),
          ],
        ),
        // 메뉴 2: 아포가토 (누적 2개, 옵션 다름)
        OrderMenu(
          menuId: 'MENU_TOTAL_002',
          menuName: '아포가토',
          quantity: 2,
          price: 7500,
          menuOptionItems: [
            MenuOptionItem(
              menuOptionItemId: 'OPT_TOTAL_002',
              menuOptionItemName: '아이스크림 선택',
              selectedItems: [
                SelectedOptionItem(
                  menuOptionItemDetailId: 'ICE_VANILLA',
                  menuOptionItemDetailName: '바닐라 아이스크림',
                  menuOptionItemDetailPrice: 0,
                  menuOptionItemDetailQuantity: 1,
                ),
                SelectedOptionItem(
                  menuOptionItemDetailId: 'ICE_CHOCOLATE',
                  menuOptionItemDetailName: '초콜릿 아이스크림',
                  menuOptionItemDetailPrice: 500,
                  menuOptionItemDetailQuantity: 1,
                ),
              ],
            ),
          ],
        ),
        // 메뉴 3: 마카롱 세트 (누적 4개)
        OrderMenu(
          menuId: 'MENU_TOTAL_003',
          menuName: '마카롱 세트 (5개입)',
          quantity: 4,
          price: 12000,
          menuOptionItems: [],
        ),
        // 메뉴 4: 밀크티 (누적 2개)
        OrderMenu(
          menuId: 'MENU_TOTAL_004',
          menuName: '타로 밀크티',
          quantity: 2,
          price: 5500,
          menuOptionItems: [
            MenuOptionItem(
              menuOptionItemId: 'OPT_TOTAL_003',
              menuOptionItemName: '펄 추가',
              selectedItems: [
                SelectedOptionItem(
                  menuOptionItemDetailId: 'PEARL_TAPIOCA',
                  menuOptionItemDetailName: '타피오카 펄',
                  menuOptionItemDetailPrice: 800,
                  menuOptionItemDetailQuantity: 2,
                ),
              ],
            ),
            MenuOptionItem(
              menuOptionItemId: 'OPT_TOTAL_004',
              menuOptionItemName: '당도 선택',
              selectedItems: [
                SelectedOptionItem(
                  menuOptionItemDetailId: 'SUGAR_HALF',
                  menuOptionItemDetailName: '50% 당도',
                  menuOptionItemDetailPrice: 0,
                  menuOptionItemDetailQuantity: 2,
                ),
              ],
            ),
          ],
        ),
        // 메뉴 5: 스콘 (누적 5개)
        OrderMenu(
          menuId: 'MENU_TOTAL_005',
          menuName: '블루베리 스콘',
          quantity: 5,
          price: 3800,
          menuOptionItems: [
            MenuOptionItem(
              menuOptionItemId: 'OPT_TOTAL_005',
              menuOptionItemName: '데우기',
              selectedItems: [
                SelectedOptionItem(
                  menuOptionItemDetailId: 'HEAT_WARM',
                  menuOptionItemDetailName: '따뜻하게',
                  menuOptionItemDetailPrice: 0,
                  menuOptionItemDetailQuantity: 5,
                ),
              ],
            ),
          ],
        ),
        // 메뉴 6: 그린티 라떼 (누적 1개)
        OrderMenu(
          menuId: 'MENU_TOTAL_006',
          menuName: '그린티 라떼 (HOT)',
          quantity: 1,
          price: 5800,
          menuOptionItems: [],
        ),
      ],
    );
  }
}
