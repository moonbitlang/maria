///|
/// Represents an asynchronous HTTP handler function.
///
/// A `Handler` receives a `RequestReader` for reading the incoming request
/// and a `ResponseWriter` for sending the HTTP response back to the client.
pub(all) struct Handler(async (RequestReader, ResponseWriter) -> Unit)
