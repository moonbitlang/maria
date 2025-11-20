///|
pub(all) enum Class {
  /// The 1xx (Informational) class of status code indicates an interim response
  /// for communicating connection status or request progress prior to
  /// completing the requested action and sending a final response.
  Informational
  /// The 2xx (Successful) class of status code indicates that the client's
  /// request was successfully received, understood, and accepted.
  Successful
  /// The 3xx (Redirection) class of status code indicates that further action
  /// needs to be taken by the user agent in order to fulfill the request
  Redirection
  /// The 4xx (Client Error) class of status code indicates that the client
  /// seems to have erred.
  ClientError
  /// The 5xx (Server Error) class of status code indicates that the server is
  /// aware that it has erred or is incapable of performing the requested method.
  ServerError
  /// Values outside the range 100..599 are invalid. Implementations often use
  /// three-digit integer values outside of that range (i.e., 600..999) for
  /// internal communication of non-HTTP status (e.g., library errors). A client
  /// that receives a response with an invalid status code SHOULD process the
  /// response as if it had a 5xx (Server Error) status code.
  Invalid
}

///|
pub fn classify(code : Int) -> Class {
  match code {
    100..=199 => Class::Informational
    200..=299 => Class::Successful
    300..=399 => Class::Redirection
    400..=499 => Class::ClientError
    500..=599 => Class::ServerError
    _ => Class::Invalid
  }
}
