class AppException implements Exception {
  final String message;
  final String prefix;

  AppException(
      [this.message = "Something went wrong", this.prefix = "Error: "]);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class NetworkException extends AppException {
  NetworkException([String message = "No Internet Connection"])
      : super(message, "Network Error: ");
}

class UploadException extends AppException {
  UploadException([String message = "Failed to upload file"])
      : super(message, "Upload Error: ");
}

class BackendException extends AppException {
  BackendException([String message = "Server returned an error"])
      : super(message, "Server Error: ");
}

class FileException extends AppException {
  FileException([String message = "File error"])
      : super(message, "File Error: ");
}
