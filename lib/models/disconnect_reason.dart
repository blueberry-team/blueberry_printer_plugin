/// 프린터 연결 끊김 이유
/// Printer disconnect reason
/// プリンター切断理由
enum DisconnectReason {
  /// 알 수 없는 이유
  /// Unknown reason
  /// 不明な理由
  unknown('UNKNOWN'),

  /// 소켓 타임아웃
  /// Socket timeout
  /// ソケットタイムアウト
  socketTimeout('SOCKET_TIMEOUT'),

  /// I/O 에러
  /// I/O error
  /// I/Oエラー
  ioError('IO_ERROR'),

  /// 소켓이 닫힘
  /// Socket closed
  /// ソケットが閉じられました
  socketClosed('SOCKET_CLOSED'),

  /// 프린터 오프라인
  /// Printer offline
  /// プリンターがオフライン
  printerOffline('PRINTER_OFFLINE'),

  /// 용지 부족
  /// Out of paper
  /// 用紙切れ
  outOfPaper('OUT_OF_PAPER'),

  /// 수동 연결 해제
  /// Manual disconnect
  /// 手動切断
  manualDisconnect('MANUAL_DISCONNECT'),

  /// 블루투스 비활성화
  /// Bluetooth disabled
  /// Bluetooth無効
  bluetoothDisabled('BLUETOOTH_DISABLED'),

  /// 연결 실패
  /// Connection failed
  /// 接続失敗
  connectionFailed('CONNECTION_FAILED');

  const DisconnectReason(this.code);

  final String code;

  /// 코드 문자열로부터 DisconnectReason 찾기
  static DisconnectReason fromCode(String code) {
    return DisconnectReason.values.firstWhere(
      (reason) => reason.code == code,
      orElse: () => DisconnectReason.unknown,
    );
  }

  /// 한국어 메시지
  String get messageKor {
    switch (this) {
      case DisconnectReason.unknown:
        return '알 수 없는 이유로 연결이 끊겼습니다';
      case DisconnectReason.socketTimeout:
        return '소켓 타임아웃으로 연결이 끊겼습니다';
      case DisconnectReason.ioError:
        return 'I/O 오류로 연결이 끊겼습니다';
      case DisconnectReason.socketClosed:
        return '소켓이 닫혀 연결이 끊겼습니다';
      case DisconnectReason.printerOffline:
        return '프린터가 오프라인 상태입니다';
      case DisconnectReason.outOfPaper:
        return '용지가 부족합니다';
      case DisconnectReason.manualDisconnect:
        return '연결이 수동으로 해제되었습니다';
      case DisconnectReason.bluetoothDisabled:
        return '블루투스가 비활성화되었습니다';
      case DisconnectReason.connectionFailed:
        return '연결에 실패했습니다';
    }
  }

  /// 영어 메시지
  String get messageEng {
    switch (this) {
      case DisconnectReason.unknown:
        return 'Connection lost for unknown reason';
      case DisconnectReason.socketTimeout:
        return 'Socket timeout';
      case DisconnectReason.ioError:
        return 'I/O error occurred';
      case DisconnectReason.socketClosed:
        return 'Socket closed';
      case DisconnectReason.printerOffline:
        return 'Printer is offline';
      case DisconnectReason.outOfPaper:
        return 'Out of paper';
      case DisconnectReason.manualDisconnect:
        return 'Manually disconnected';
      case DisconnectReason.bluetoothDisabled:
        return 'Bluetooth is disabled';
      case DisconnectReason.connectionFailed:
        return 'Connection failed';
    }
  }

  /// 일본어 메시지
  String get messageJpn {
    switch (this) {
      case DisconnectReason.unknown:
        return '不明な理由で接続が切れました';
      case DisconnectReason.socketTimeout:
        return 'ソケットタイムアウト';
      case DisconnectReason.ioError:
        return 'I/Oエラーが発生しました';
      case DisconnectReason.socketClosed:
        return 'ソケットが閉じられました';
      case DisconnectReason.printerOffline:
        return 'プリンターがオフラインです';
      case DisconnectReason.outOfPaper:
        return '用紙切れ';
      case DisconnectReason.manualDisconnect:
        return '手動で切断されました';
      case DisconnectReason.bluetoothDisabled:
        return 'Bluetoothが無効になっています';
      case DisconnectReason.connectionFailed:
        return '接続に失敗しました';
    }
  }

  /// 언어에 따른 메시지 가져오기
  String getMessage(String language) {
    switch (language) {
      case 'eng':
        return messageEng;
      case 'jpn':
        return messageJpn;
      default: // 'kor'
        return messageKor;
    }
  }
}
