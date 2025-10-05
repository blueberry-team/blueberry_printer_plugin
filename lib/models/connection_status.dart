import 'disconnect_reason.dart';

/// 프린터 연결 상태
class ConnectionStatus {
  /// 연결 상태 (connected, disconnected)
  final String status;

  /// 상태 메시지
  final String message;

  /// 연결 끊김 이유 enum (disconnected일 때만)
  final DisconnectReason? disconnectReason;

  ConnectionStatus({
    required this.status,
    required this.message,
    this.disconnectReason,
  });

  /// Map에서 ConnectionStatus 객체 생성
  factory ConnectionStatus.fromMap(Map<dynamic, dynamic> map) {
    final reasonCode = map['reason'] as String?;
    return ConnectionStatus(
      status: map['status'] as String,
      message: map['message'] as String,
      disconnectReason: reasonCode != null
          ? DisconnectReason.fromCode(reasonCode)
          : null,
    );
  }

  /// 연결됨 상태인지 확인
  bool get isConnected => status == 'connected';

  /// 연결 끊김 상태인지 확인
  bool get isDisconnected => status == 'disconnected';

  /// 다국어 메시지 가져오기 (한국어/영어/일본어)
  String getLocalizedMessage(String language) {
    if (isConnected) {
      switch (language) {
        case 'eng':
          return 'Printer connected';
        case 'jpn':
          return 'プリンターが接続されました';
        default:
          return '프린터가 연결되었습니다';
      }
    } else if (disconnectReason != null) {
      return disconnectReason!.getMessage(language);
    } else {
      return message;
    }
  }

  @override
  String toString() {
    return 'ConnectionStatus(status: $status, message: $message, reason: ${disconnectReason?.code})';
  }
}
