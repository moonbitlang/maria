///|
pub fn reason(status : Int) -> String {
  match status {
    @status.Continue => @reason.Continue
    @status.SwitchingProtocols => @reason.SwitchingProtocols
    @status.Processing => @reason.Processing
    @status.EarlyHints => @reason.EarlyHints
    @status.Ok => @reason.Ok
    @status.Created => @reason.Created
    @status.Accepted => @reason.Accepted
    @status.NonAuthoritativeInformation => @reason.NonAuthoritativeInformation
    @status.NoContent => @reason.NoContent
    @status.ResetContent => @reason.ResetContent
    @status.PartialContent => @reason.PartialContent
    @status.MultiStatus => @reason.MultiStatus
    @status.AlreadyReported => @reason.AlreadyReported
    @status.ImUsed => @reason.ImUsed
    @status.MultipleChoices => @reason.MultipleChoices
    @status.MovedPermanently => @reason.MovedPermanently
    @status.Found => @reason.Found
    @status.SeeOther => @reason.SeeOther
    @status.NotModified => @reason.NotModified
    @status.UseProxy => @reason.UseProxy
    @status.TemporaryRedirect => @reason.TemporaryRedirect
    @status.PermanentRedirect => @reason.PermanentRedirect
    @status.BadRequest => @reason.BadRequest
    @status.Unauthorized => @reason.Unauthorized
    @status.PaymentRequired => @reason.PaymentRequired
    @status.Forbidden => @reason.Forbidden
    @status.NotFound => @reason.NotFound
    @status.MethodNotAllowed => @reason.MethodNotAllowed
    @status.NotAcceptable => @reason.NotAcceptable
    @status.ProxyAuthenticationRequired => @reason.ProxyAuthenticationRequired
    @status.RequestTimeout => @reason.RequestTimeout
    @status.Conflict => @reason.Conflict
    @status.Gone => @reason.Gone
    @status.LengthRequired => @reason.LengthRequired
    @status.PreconditionFailed => @reason.PreconditionFailed
    @status.PayloadTooLarge => @reason.PayloadTooLarge
    @status.UriTooLong => @reason.UriTooLong
    @status.UnsupportedMediaType => @reason.UnsupportedMediaType
    @status.RangeNotSatisfiable => @reason.RangeNotSatisfiable
    @status.ExpectationFailed => @reason.ExpectationFailed
    @status.ImATeapot => @reason.ImATeapot
    @status.MisdirectedRequest => @reason.MisdirectedRequest
    @status.UnprocessableEntity => @reason.UnprocessableEntity
    @status.Locked => @reason.Locked
    @status.FailedDependency => @reason.FailedDependency
    @status.TooEarly => @reason.TooEarly
    @status.UpgradeRequired => @reason.UpgradeRequired
    @status.PreconditionRequired => @reason.PreconditionRequired
    @status.TooManyRequests => @reason.TooManyRequests
    @status.RequestHeaderFieldsTooLarge => @reason.RequestHeaderFieldsTooLarge
    @status.UnavailableForLegalReasons => @reason.UnavailableForLegalReasons
    @status.InternalServerError => @reason.InternalServerError
    @status.NotImplemented => @reason.NotImplemented
    @status.BadGateway => @reason.BadGateway
    @status.ServiceUnavailable => @reason.ServiceUnavailable
    @status.GatewayTimeout => @reason.GatewayTimeout
    @status.HttpVersionNotSupported => @reason.HttpVersionNotSupported
    @status.VariantAlsoNegotiates => @reason.VariantAlsoNegotiates
    @status.InsufficientStorage => @reason.InsufficientStorage
    @status.LoopDetected => @reason.LoopDetected
    @status.NotExtended => @reason.NotExtended
    @status.NetworkAuthenticationRequired =>
      @reason.NetworkAuthenticationRequired
    unknown =>
      match @status.classify(unknown) {
        Informational => "Informational \{unknown}"
        Successful => "Successful \{unknown}"
        Redirection => "Redirection \{unknown}"
        ClientError => "Client Error \{unknown}"
        ServerError => "Server Error \{unknown}"
        Invalid => "Invalid \{unknown}"
      }
  }
}
