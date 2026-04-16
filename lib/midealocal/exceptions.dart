/// Midea Local library exceptions. Mirrors midealocal/exceptions.py.

class MideaLocalError implements Exception {
  MideaLocalError([this.message]);
  final String? message;

  @override
  String toString() =>
      message != null ? 'MideaLocalError: $message' : 'MideaLocalError';
}

class CannotAuthenticate extends MideaLocalError {
  CannotAuthenticate([super.message]);
}

class CannotConnect extends MideaLocalError {
  CannotConnect([super.message]);
}

class DataUnexpectedLength extends MideaLocalError {
  DataUnexpectedLength([super.message]);
}

class DataSignDoesntMatch extends MideaLocalError {
  DataSignDoesntMatch([super.message]);
}

class DataSignWrongType extends MideaLocalError {
  DataSignWrongType([super.message]);
}

class ElementMissing extends MideaLocalError {
  ElementMissing([super.message]);
}

class MessageWrongFormat extends MideaLocalError {
  MessageWrongFormat([super.message]);
}

class SocketException extends MideaLocalError {
  SocketException([super.message]);
}

class ValueWrongType extends MideaLocalError {
  ValueWrongType([super.message]);
}
