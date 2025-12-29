///|
struct ResponseOutputItemDoneEvent {
  /// The output item that was marked done.
  item : ResponseOutputItem
  /// The index of the output item that was marked done.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}
