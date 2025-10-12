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

// ========== 영어 (English) 샘플 ==========

/// English Socket Notification Sample
Map<String, dynamic> getSampleSocketNotificationEnglish() {
  return {
    "orderBy": "TABLE",
    "tableNumber": 3,
    "orderAt": "2025-10-09T14:43:00",
    "orderType": "CREATE",
    "items": [
      {
        "menuName": "Americano (ICE)",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "Syrup",
            "optionDetails": [
              {"name": "Vanilla", "quantity": 1},
              {"name": "Caramel", "quantity": 1}
            ]
          },
          {
            "name": "Ice",
            "optionDetails": [
              {"name": "Light Ice", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "Cafe Latte (HOT)",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "Milk",
            "optionDetails": [
              {"name": "Soy Milk", "quantity": 1}
            ]
          },
          {
            "name": "Extra",
            "optionDetails": [
              {"name": "Extra Shot", "quantity": 2}
            ]
          }
        ]
      },
      {
        "menuName": "Blueberry Muffin",
        "quantity": 3,
        "itemOptions": []
      }
    ]
  };
}

/// English Update Notification Sample
Map<String, dynamic> getSampleUpdateNotificationEnglish() {
  return {
    "orderBy": "ADMIN",
    "tableNumber": 7,
    "orderAt": "2025-10-09T15:20:00",
    "orderType": "UPDATE",
    "items": [
      {
        "menuName": "Cafe Mocha (ICE)",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "Whipped Cream",
            "optionDetails": [
              {"name": "Extra Whip", "quantity": 1}
            ]
          },
          {
            "name": "Syrup",
            "optionDetails": [
              {"name": "Hazelnut", "quantity": 1},
              {"name": "Chocolate", "quantity": 2}
            ]
          }
        ]
      },
      {
        "menuName": "Green Tea Latte (HOT)",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "Milk",
            "optionDetails": [
              {"name": "Oat Milk", "quantity": 1}
            ]
          },
          {
            "name": "Sweetness",
            "optionDetails": [
              {"name": "Less Sweet", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "Cheesecake",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "Topping",
            "optionDetails": [
              {"name": "Strawberry", "quantity": 1}
            ]
          }
        ]
      }
    ]
  };
}

/// English Cancel Notification Sample
Map<String, dynamic> getSampleCancelNotificationEnglish() {
  return {
    "orderBy": "TABLE",
    "tableNumber": 9,
    "orderAt": "2025-10-09T16:15:00",
    "orderType": "CANCELLED",
    "items": [
      {
        "menuName": "Espresso",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "Shot",
            "optionDetails": [
              {"name": "Double Shot", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "Flat White",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "Milk",
            "optionDetails": [
              {"name": "Almond Milk", "quantity": 1}
            ]
          }
        ]
      }
    ]
  };
}

// ========== 일본어 (Japanese) 샘플 ==========

/// Japanese Socket Notification Sample
Map<String, dynamic> getSampleSocketNotificationJapanese() {
  return {
    "orderBy": "TABLE",
    "tableNumber": 4,
    "orderAt": "2025-10-09T14:43:00",
    "orderType": "CREATE",
    "items": [
      {
        "menuName": "アメリカーノ (アイス)",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "シロップ",
            "optionDetails": [
              {"name": "バニラ", "quantity": 1},
              {"name": "キャラメル", "quantity": 1}
            ]
          },
          {
            "name": "氷",
            "optionDetails": [
              {"name": "少なめ", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "カフェラテ (ホット)",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "ミルク",
            "optionDetails": [
              {"name": "豆乳", "quantity": 1}
            ]
          },
          {
            "name": "追加",
            "optionDetails": [
              {"name": "ショット追加", "quantity": 2}
            ]
          }
        ]
      },
      {
        "menuName": "ブルーベリーマフィン",
        "quantity": 3,
        "itemOptions": []
      }
    ]
  };
}

/// Japanese Update Notification Sample
Map<String, dynamic> getSampleUpdateNotificationJapanese() {
  return {
    "orderBy": "ADMIN",
    "tableNumber": 6,
    "orderAt": "2025-10-09T15:20:00",
    "orderType": "UPDATE",
    "items": [
      {
        "menuName": "カフェモカ (アイス)",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "ホイップクリーム",
            "optionDetails": [
              {"name": "多め", "quantity": 1}
            ]
          },
          {
            "name": "シロップ",
            "optionDetails": [
              {"name": "ヘーゼルナッツ", "quantity": 1},
              {"name": "チョコレート", "quantity": 2}
            ]
          }
        ]
      },
      {
        "menuName": "グリーンティーラテ (ホット)",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "ミルク",
            "optionDetails": [
              {"name": "オーツミルク", "quantity": 1}
            ]
          },
          {
            "name": "甘さ",
            "optionDetails": [
              {"name": "控えめ", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "チーズケーキ",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "トッピング",
            "optionDetails": [
              {"name": "いちご", "quantity": 1}
            ]
          }
        ]
      }
    ]
  };
}

/// Japanese Cancel Notification Sample
Map<String, dynamic> getSampleCancelNotificationJapanese() {
  return {
    "orderBy": "TABLE",
    "tableNumber": 10,
    "orderAt": "2025-10-09T16:15:00",
    "orderType": "CANCELLED",
    "items": [
      {
        "menuName": "エスプレッソ",
        "quantity": 2,
        "itemOptions": [
          {
            "name": "ショット",
            "optionDetails": [
              {"name": "ダブルショット", "quantity": 1}
            ]
          }
        ]
      },
      {
        "menuName": "フラットホワイト",
        "quantity": 1,
        "itemOptions": [
          {
            "name": "ミルク",
            "optionDetails": [
              {"name": "アーモンドミルク", "quantity": 1}
            ]
          }
        ]
      }
    ]
  };
}
