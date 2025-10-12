/// 소켓 주문 알림 샘플 데이터
Map<String, dynamic> getSampleSocketNotification() {
  return {
    "orderBy": "TABLE",
    "tableNumber": 2,
    "orderAt": "2025-10-09T14:43:00",
    "orderType": "CREATE",
    "items": [
      {
        "menuName": "아메리카노 (ICE)",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "시럽",
            "optionDetails": [
              {"name": "바닐라", "quantity": 1},
              {"name": "캐러멜", "quantity": 1}
            ]
          },
          {
            "name": "얼음",
            "optionDetails": [
              {"name": "적게", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "카페라떼 (HOT)",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "우유",
            "optionDetails": [
              {"name": "두유", "quantity": 1}
            ]
          },
          {
            "name": "추가",
            "optionDetails": [
              {"name": "샷 추가", "quantity": 2}
            ]
          }
        ]
      },
      {
        "menuName": "블루베리 머핀",
        "quantity": 3,
        "itemOptions": []
      }
    ]
  };
}

/// 주문 변경 샘플
Map<String, dynamic> getSampleUpdateNotification() {
  return {
    "orderBy": "ADMIN",
    "tableNumber": 5,
    "orderAt": "2025-10-09T15:20:00",
    "orderType": "UPDATE",
    "items": [
      {
        "menuName": "카페모카 (ICE)",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "휘핑크림",
            "optionDetails": [
              {"name": "많이", "quantity": 1}
            ]
          },
          {
            "name": "시럽",
            "optionDetails": [
              {"name": "헤이즐넛", "quantity": 1},
              {"name": "초콜릿", "quantity": 2}
            ]
          }
        ]
      },
      {
        "menuName": "그린티 라떼 (HOT)",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "우유",
            "optionDetails": [
              {"name": "오트밀크", "quantity": 1}
            ]
          },
          {
            "name": "당도",
            "optionDetails": [
              {"name": "덜 달게", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "치즈케이크",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "토핑",
            "optionDetails": [
              {"name": "딸기", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "크루아상",
        "quantity": 1,
        "itemOptions": []
      }
    ]
  };
}

/// 주문 취소 샘플
Map<String, dynamic> getSampleCancelNotification() {
  return {
    "orderBy": "TABLE",
    "tableNumber": 8,
    "orderAt": "2025-10-09T16:15:00",
    "orderType": "CANCELLED",
    "items": [
      {
        "menuName": "에스프레소",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "샷",
            "optionDetails": [
              {"name": "더블샷", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "플랫화이트",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "우유",
            "optionDetails": [
              {"name": "아몬드밀크", "quantity": 1}
            ]
          }
        ]
      }
    ]
  };
}
