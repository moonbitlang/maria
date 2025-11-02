///|
pub async fn render_diagnostics(
  diagnostics : ArrayView[@diagnostics.Diagnostic],
  limit~ : Int,
  context? : Int = 0,
  overlay? : Map[String, String] = {},
  cwd? : String,
) -> String noraise {
  @diagnostics.render_diagnostics(diagnostics, limit~, context~, overlay~, cwd?)
}
