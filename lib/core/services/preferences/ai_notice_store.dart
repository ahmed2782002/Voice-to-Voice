abstract interface class AiNoticeStore {
  bool get seen;

  Future<void> markSeen();
}
