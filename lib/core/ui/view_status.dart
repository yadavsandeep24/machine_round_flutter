enum ViewStatus { initial, loading, success, failure }

extension ViewStatusX on ViewStatus {
  bool get isLoading => this == ViewStatus.loading;
  bool get isSuccess => this == ViewStatus.success;
  bool get isFailure => this == ViewStatus.failure;
}
