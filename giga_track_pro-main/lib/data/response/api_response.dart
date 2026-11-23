import 'package:trackerapp/data/response/status.dart';

/// Generic API Response wrapper for handling async data states
class ApiResponse<T> {
  final Status status;
  final T? data;
  final String? error;

  const ApiResponse({
    required this.status,
    this.data,
    this.error,
  });

  /// Loading state constructor
  ApiResponse.loading()
      : status = Status.LOADING,
        data = null,
        error = null {
    print("⏳ ApiResponse Loading Created");
  }

  /// Success state constructor
  ApiResponse.complete(T data)
      : status = Status.COMPLETED,
        data = data,
        error = null {
    print("✅ ApiResponse Success");
    print("Data: $data");
  }

  /// Error state constructor
  ApiResponse.error(String message)
      : status = Status.ERROR,
        data = null,
        error = message {
    print("❌ ApiResponse Error");
    print("Message: $message");
  }

  /// Check if data is loading
  bool get isLoading => status == Status.LOADING;

  /// Check if data loaded successfully
  bool get isCompleted => status == Status.COMPLETED;

  /// Check if error occurred
  bool get hasError => status == Status.ERROR;

  /// Check if data is available
  bool get hasData => data != null;

  /// Get error message or default
  String get errorMessage => error ?? 'An unexpected error occurred';

  /// Execute callback based on status
  void when({
    required Function() onLoading,
    required Function(T data) onSuccess,
    required Function(String error) onError,
  }) {
    print("🔄 when() called → Status: $status");

    switch (status) {
      case Status.LOADING:
        print("⏳ Executing Loading Callback");
        onLoading();
        break;

      case Status.COMPLETED:
        print("✅ Executing Success Callback");
        if (hasData) {
          print("Returned Data: $data");
          onSuccess(data as T);
        }
        break;

      case Status.ERROR:
        print("❌ Executing Error Callback");
        print("Error: $errorMessage");
        onError(errorMessage);
        break;

      default:
        print("⚠️ Unknown State");
        onError('Unknown state');
    }
  }

  /// Map data to another type
  ApiResponse<R> map<R>(R Function(T) transform) {
    print("🔄 map() called");

    if (!hasData) {
      print("⚠️ No data available for mapping");

      return ApiResponse<R>(
        status: status,
        error: error,
      );
    }

    try {
      print("Input Data: $data");

      final transformed = transform(data as T);

      print("Mapped Data: $transformed");

      return ApiResponse.complete(transformed);
    } catch (e) {
      print("❌ Map Error: $e");

      return ApiResponse.error('Failed to transform data: $e');
    }
  }

  /// Create a new response with updated data
  ApiResponse<T> copyWith({
    Status? status,
    T? data,
    String? error,
  }) {
    print("🔄 copyWith() called");
    print("New Status: ${status ?? this.status}");
    print("New Data: ${data ?? this.data}");
    print("New Error: ${error ?? this.error}");

    return ApiResponse(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'ApiResponse<$T>(\n'
        '  status: $status,\n'
        '  hasData: $hasData,\n'
        '  data: $data,\n'
        '  error: $error,\n'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ApiResponse<T> &&
        other.status == status &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => status.hashCode ^ data.hashCode ^ error.hashCode;
}