///|
test "status" {
  @json.inspect(@httpx.reason(@status.Continue), content="Continue")
  @json.inspect(
    @httpx.reason(@status.SwitchingProtocols),
    content="Switching Protocols",
  )
  @json.inspect(@httpx.reason(@status.Processing), content="Processing")
  @json.inspect(@httpx.reason(@status.EarlyHints), content="Early Hints")
  @json.inspect(@httpx.reason(@status.Ok), content="OK")
  @json.inspect(@httpx.reason(@status.Created), content="Created")
  @json.inspect(@httpx.reason(@status.Accepted), content="Accepted")
  @json.inspect(
    @httpx.reason(@status.NonAuthoritativeInformation),
    content="Non-Authoritative Information",
  )
  @json.inspect(@httpx.reason(@status.NoContent), content="No Content")
  @json.inspect(@httpx.reason(@status.ResetContent), content="Reset Content")
  @json.inspect(
    @httpx.reason(@status.PartialContent),
    content="Partial Content",
  )
  @json.inspect(@httpx.reason(@status.MultiStatus), content="Multi-Status")
  @json.inspect(
    @httpx.reason(@status.AlreadyReported),
    content="Already Reported",
  )
  @json.inspect(@httpx.reason(@status.ImUsed), content="IM Used")
  @json.inspect(
    @httpx.reason(@status.MultipleChoices),
    content="Multiple Choices",
  )
  @json.inspect(
    @httpx.reason(@status.MovedPermanently),
    content="Moved Permanently",
  )
  @json.inspect(@httpx.reason(@status.Found), content="Found")
  @json.inspect(@httpx.reason(@status.SeeOther), content="See Other")
  @json.inspect(@httpx.reason(@status.NotModified), content="Not Modified")
  @json.inspect(@httpx.reason(@status.UseProxy), content="Use Proxy")
  @json.inspect(
    @httpx.reason(@status.TemporaryRedirect),
    content="Temporary Redirect",
  )
  @json.inspect(
    @httpx.reason(@status.PermanentRedirect),
    content="Permanent Redirect",
  )
  @json.inspect(@httpx.reason(@status.BadRequest), content="Bad Request")
  @json.inspect(@httpx.reason(@status.Unauthorized), content="Unauthorized")
  @json.inspect(
    @httpx.reason(@status.PaymentRequired),
    content="Payment Required",
  )
  @json.inspect(@httpx.reason(@status.Forbidden), content="Forbidden")
  @json.inspect(@httpx.reason(@status.NotFound), content="Not Found")
  @json.inspect(
    @httpx.reason(@status.MethodNotAllowed),
    content="Method Not Allowed",
  )
  @json.inspect(@httpx.reason(@status.NotAcceptable), content="Not Acceptable")
  @json.inspect(
    @httpx.reason(@status.ProxyAuthenticationRequired),
    content="Proxy Authentication Required",
  )
  @json.inspect(
    @httpx.reason(@status.RequestTimeout),
    content="Request Timeout",
  )
  @json.inspect(@httpx.reason(@status.Conflict), content="Conflict")
  @json.inspect(@httpx.reason(@status.Gone), content="Gone")
  @json.inspect(
    @httpx.reason(@status.LengthRequired),
    content="Length Required",
  )
  @json.inspect(
    @httpx.reason(@status.PreconditionFailed),
    content="Precondition Failed",
  )
  @json.inspect(
    @httpx.reason(@status.PayloadTooLarge),
    content="Payload Too Large",
  )
  @json.inspect(@httpx.reason(@status.UriTooLong), content="URI Too Long")
  @json.inspect(
    @httpx.reason(@status.UnsupportedMediaType),
    content="Unsupported Media Type",
  )
  @json.inspect(
    @httpx.reason(@status.RangeNotSatisfiable),
    content="Range Not Satisfiable",
  )
  @json.inspect(
    @httpx.reason(@status.ExpectationFailed),
    content="Expectation Failed",
  )
  @json.inspect(@httpx.reason(@status.ImATeapot), content="I'm a teapot")
  @json.inspect(
    @httpx.reason(@status.MisdirectedRequest),
    content="Misdirected Request",
  )
  @json.inspect(
    @httpx.reason(@status.UnprocessableEntity),
    content="Unprocessable Entity",
  )
  @json.inspect(@httpx.reason(@status.Locked), content="Locked")
  @json.inspect(
    @httpx.reason(@status.FailedDependency),
    content="Failed Dependency",
  )
  @json.inspect(@httpx.reason(@status.TooEarly), content="Too Early")
  @json.inspect(
    @httpx.reason(@status.UpgradeRequired),
    content="Upgrade Required",
  )
  @json.inspect(
    @httpx.reason(@status.PreconditionRequired),
    content="Precondition Required",
  )
  @json.inspect(
    @httpx.reason(@status.TooManyRequests),
    content="Too Many Requests",
  )
  @json.inspect(
    @httpx.reason(@status.RequestHeaderFieldsTooLarge),
    content="Request Header Fields Too Large",
  )
  @json.inspect(
    @httpx.reason(@status.UnavailableForLegalReasons),
    content="Unavailable For Legal Reasons",
  )
  @json.inspect(
    @httpx.reason(@status.InternalServerError),
    content="Internal Server Error",
  )
  @json.inspect(
    @httpx.reason(@status.NotImplemented),
    content="Not Implemented",
  )
  @json.inspect(@httpx.reason(@status.BadGateway), content="Bad Gateway")
  @json.inspect(
    @httpx.reason(@status.ServiceUnavailable),
    content="Service Unavailable",
  )
  @json.inspect(
    @httpx.reason(@status.GatewayTimeout),
    content="Gateway Timeout",
  )
  @json.inspect(
    @httpx.reason(@status.HttpVersionNotSupported),
    content="HTTP Version Not Supported",
  )
  @json.inspect(
    @httpx.reason(@status.VariantAlsoNegotiates),
    content="Variant Also Negotiates",
  )
  @json.inspect(
    @httpx.reason(@status.InsufficientStorage),
    content="Insufficient Storage",
  )
  @json.inspect(@httpx.reason(@status.LoopDetected), content="Loop Detected")
  @json.inspect(@httpx.reason(@status.NotExtended), content="Not Extended")
  @json.inspect(
    @httpx.reason(@status.NetworkAuthenticationRequired),
    content="Network Authentication Required",
  )
  @json.inspect(@httpx.reason(150), content="Informational 150")
  @json.inspect(@httpx.reason(250), content="Successful 250")
  @json.inspect(@httpx.reason(310), content="Redirection 310")
  @json.inspect(@httpx.reason(450), content="Client Error 450")
  @json.inspect(@httpx.reason(599), content="Server Error 599")
  @json.inspect(@httpx.reason(600), content="Invalid 600")
}
