///|
pub extern "c" fn atexit(func : FuncRef[() -> Unit]) -> Int = "atexit"
