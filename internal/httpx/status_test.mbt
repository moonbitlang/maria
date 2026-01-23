///|
test "status" {
  json_inspect(@httpx.reason(@status.Continue), content="Continue")
  json_inspect(
    @httpx.reason(@status.SwitchingProtocols),
    content="Switching Protocols",
  )
  json_inspect(@httpx.reason(@status.Processing), content="Processing")
  json_inspect(@httpx.reason(@status.EarlyHints), content="Early Hints")
  json_inspect(@httpx.reason(@status.Ok), content="OK")
  json_inspect(@httpx.reason(@status.Created), content="Created")
  json_inspect(@httpx.reason(@status.Accepted), content="Accepted")
  json_inspect(
    @httpx.reason(@status.NonAuthoritativeInformation),
    content="Non-Authoritative Information",
  )
  json_inspect(@httpx.reason(@status.NoContent), content="No Content")
  json_inspect(@httpx.reason(@status.ResetContent), content="Reset Content")
  json_inspect(@httpx.reason(@status.PartialContent), content="Partial Content")
  json_inspect(@httpx.reason(@status.MultiStatus), content="Multi-Status")
  json_inspect(
    @httpx.reason(@status.AlreadyReported),
    content="Already Reported",
  )
  json_inspect(@httpx.reason(@status.ImUsed), content="IM Used")
  json_inspect(
    @httpx.reason(@status.MultipleChoices),
    content="Multiple Choices",
  )
  json_inspect(
    @httpx.reason(@status.MovedPermanently),
    content="Moved Permanently",
  )
  json_inspect(@httpx.reason(@status.Found), content="Found")
  json_inspect(@httpx.reason(@status.SeeOther), content="See Other")
  json_inspect(@httpx.reason(@status.NotModified), content="Not Modified")
  json_inspect(@httpx.reason(@status.UseProxy), content="Use Proxy")
  json_inspect(
    @httpx.reason(@status.TemporaryRedirect),
    content="Temporary Redirect",
  )
  json_inspect(
    @httpx.reason(@status.PermanentRedirect),
    content="Permanent Redirect",
  )
  json_inspect(@httpx.reason(@status.BadRequest), content="Bad Request")
  json_inspect(@httpx.reason(@status.Unauthorized), content="Unauthorized")
  json_inspect(
    @httpx.reason(@status.PaymentRequired),
    content="Payment Required",
  )
  json_inspect(@httpx.reason(@status.Forbidden), content="Forbidden")
  json_inspect(@httpx.reason(@status.NotFound), content="Not Found")
  json_inspect(
    @httpx.reason(@status.MethodNotAllowed),
    content="Method Not Allowed",
  )
  json_inspect(@httpx.reason(@status.NotAcceptable), content="Not Acceptable")
  json_inspect(
    @httpx.reason(@status.ProxyAuthenticationRequired),
    content="Proxy Authentication Required",
  )
  json_inspect(@httpx.reason(@status.RequestTimeout), content="Request Timeout")
  json_inspect(@httpx.reason(@status.Conflict), content="Conflict")
  json_inspect(@httpx.reason(@status.Gone), content="Gone")
  json_inspect(@httpx.reason(@status.LengthRequired), content="Length Required")
  json_inspect(
    @httpx.reason(@status.PreconditionFailed),
    content="Precondition Failed",
  )
  json_inspect(
    @httpx.reason(@status.PayloadTooLarge),
    content="Payload Too Large",
  )
  json_inspect(@httpx.reason(@status.UriTooLong), content="URI Too Long")
  json_inspect(
    @httpx.reason(@status.UnsupportedMediaType),
    content="Unsupported Media Type",
  )
  json_inspect(
    @httpx.reason(@status.RangeNotSatisfiable),
    content="Range Not Satisfiable",
  )
  json_inspect(
    @httpx.reason(@status.ExpectationFailed),
    content="Expectation Failed",
  )
  json_inspect(@httpx.reason(@status.ImATeapot), content="I'm a teapot")
  json_inspect(
    @httpx.reason(@status.MisdirectedRequest),
    content="Misdirected Request",
  )
  json_inspect(
    @httpx.reason(@status.UnprocessableEntity),
    content="Unprocessable Entity",
  )
  json_inspect(@httpx.reason(@status.Locked), content="Locked")
  json_inspect(
    @httpx.reason(@status.FailedDependency),
    content="Failed Dependency",
  )
  json_inspect(@httpx.reason(@status.TooEarly), content="Too Early")
  json_inspect(
    @httpx.reason(@status.UpgradeRequired),
    content="Upgrade Required",
  )
  json_inspect(
    @httpx.reason(@status.PreconditionRequired),
    content="Precondition Required",
  )
  json_inspect(
    @httpx.reason(@status.TooManyRequests),
    content="Too Many Requests",
  )
  json_inspect(
    @httpx.reason(@status.RequestHeaderFieldsTooLarge),
    content="Request Header Fields Too Large",
  )
  json_inspect(
    @httpx.reason(@status.UnavailableForLegalReasons),
    content="Unavailable For Legal Reasons",
  )
  json_inspect(
    @httpx.reason(@status.InternalServerError),
    content="Internal Server Error",
  )
  json_inspect(@httpx.reason(@status.NotImplemented), content="Not Implemented")
  json_inspect(@httpx.reason(@status.BadGateway), content="Bad Gateway")
  json_inspect(
    @httpx.reason(@status.ServiceUnavailable),
    content="Service Unavailable",
  )
  json_inspect(@httpx.reason(@status.GatewayTimeout), content="Gateway Timeout")
  json_inspect(
    @httpx.reason(@status.HttpVersionNotSupported),
    content="HTTP Version Not Supported",
  )
  json_inspect(
    @httpx.reason(@status.VariantAlsoNegotiates),
    content="Variant Also Negotiates",
  )
  json_inspect(
    @httpx.reason(@status.InsufficientStorage),
    content="Insufficient Storage",
  )
  json_inspect(@httpx.reason(@status.LoopDetected), content="Loop Detected")
  json_inspect(@httpx.reason(@status.NotExtended), content="Not Extended")
  json_inspect(
    @httpx.reason(@status.NetworkAuthenticationRequired),
    content="Network Authentication Required",
  )
  json_inspect(@httpx.reason(150), content="Informational 150")
  json_inspect(@httpx.reason(250), content="Successful 250")
  json_inspect(@httpx.reason(310), content="Redirection 310")
  json_inspect(@httpx.reason(450), content="Client Error 450")
  json_inspect(@httpx.reason(599), content="Server Error 599")
  json_inspect(@httpx.reason(600), content="Invalid 600")
}
