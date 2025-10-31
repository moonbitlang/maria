///|
priv struct Env {
  generated : Array[@syntax.Impl]
}

///|
using @list {type List, empty}

///|
const NAMESPACE = "json"

///|
const SCHEMA = "schema"

///|
const DEFAULT = "default"

///|
const ENUM = "enumerate"

///|
const GENERATED = "generated"

///|
fn is_derive_pretty(attrs : List[@attribute.Attribute]) -> Bool {
  for attr in attrs {
    if attr.parsed is Some(Ident({ qual: Some(NAMESPACE), name: SCHEMA })) {
      return true
    }
  }
  false
}

///|
fn is_generated(attrs : List[@attribute.Attribute]) -> Bool {
  for attr in attrs {
    if attr.parsed is Some(Ident({ qual: Some(NAMESPACE), name: GENERATED })) {
      return true
    }
  }
  false
}

///|
let pos : @basic.Position = { cnum: 0, fname: "", lnum: 0, bol: 0 }

///|
let loc : @basic.Location = { start: pos, end: pos }

///|
fn mk_constr(constr : String) -> @syntax.ConstrId {
  { id: Ident(name=constr), loc }
}

// ///|
// fn mk_binder(binder : String) -> @syntax.Binder {
//   { name: binder, loc }
// }

///|
fn mk_json_object(map : Array[(String, @syntax.Expr)]) -> @syntax.Expr {
  let elems : List[@syntax.MapExprElem] = List::from_iter(
    map
    .iter()
    .map(fn(p) {
      let key : @syntax.Constant = String(p.0)
      { key, expr: p.1, key_loc: loc, loc }
    }),
  )
  Map(elems~, loc~)
}

///|
struct Property {
  name : String
  type_ : Schema
  default : Constant?
  description : String
}

///|
enum Schema {
  String(mut enums~ : Array[Constant]?) //(min_len~ : Int?, max_len~ : Int?, format~ : String?, enum_~ : Array[String]?)
  Boolean
  Integer //(min~ : Int?, max~ : Int?, mut enums~ : Array[Constant]?)
  Number
  Object(properties~ : Array[Property], required~ : Array[String])
  Array(item~ : Schema)
  Nullable(Schema)
}

///|
enum Constant {
  String(String)
  Integer(String)
  Number(String)
  Boolean(Bool)
}

///|
fn ty_to_schema(ty : @syntax.Type) -> Schema {
  match ty {
    Option(ty=Option(_), loc~, ..) =>
      abort("Json schema error (\{loc}): type `T??` is unsupported.")
    Option(ty~, ..) => Nullable(ty_to_schema(ty))
    Name(constr_id={ id: Ident(name="Array"), .. }, tys=More(ety, ..), ..) =>
      Array(item=ty_to_schema(ety))
    Name(constr_id={ id: Ident(name~), .. }, tys=Empty, ..) =>
      match name {
        "String" => String(enums=None)
        "Int" => Integer
        "Bool" => Boolean
        "Double" => Number
        _ => abort("Json schema error: type \{name} is not supported yet.")
      }
    Tuple(..) => abort("Json schema error: tuple type is not supported yet.")
    Object(_) => abort("Json schema error: trait object is not supported.")
    Any(_) => abort("Internal error: Any")
    Name(..) => abort("Json schema error: unsupported type")
    Arrow(_) => abort("Json schema error: function type is not supported.")
  }
}

///|
fn field_enumerate(attrs : List[@attribute.Attribute]) -> Array[Constant]? {
  fn is_string(x) {
    x is @attribute.Prop::Expr(String(_))
  }

  for attr in attrs {
    if attr.parsed is Some(Apply({ qual: Some(NAMESPACE), name: ENUM }, props)) {
      guard props
        is More(
          Expr(
            Apply(
              { qual: None, name: "string" | "integer" | "number" as name },
              xs
            )
          ),
          tail=Empty
        ) &&
        xs.all(is_string) else {
        abort(
          (
            $| Json schema error: invalid enumerate attribute.
            $| Hint: The syntax is 
            $| #\{NAMESPACE}.\{ENUM}(string(\"s1\", \"s2\"))
            $| #\{NAMESPACE}.\{ENUM}(integer(\"1\", \"2\")) 
            $| #\{NAMESPACE}.\{ENUM}(number(\"1.0\", \"2.0\"))
          ),
        )
      }
      let xs = xs
        .map(x => match x {
          Expr(String(s)) => s
          _ => abort("unreachable")
        })
        .to_array()
      let enums = match name {
        "string" => xs.map(x => Constant::String(x))
        "integer" => xs.map(x => Constant::Integer(x))
        "number" => xs.map(x => Constant::Number(x))
        _ => abort("unreachable")
      }
      break Some(enums)
    }
  } else {
    None
  }
}

///|
fn field_default(attrs : List[@attribute.Attribute]) -> Constant? {
  for attr in attrs {
    if attr.parsed
      is Some(
        Apply(
          { qual: Some(NAMESPACE), name: DEFAULT },
          More(
            Expr(Apply({ qual: None, name }, More(Expr(expr), tail=Empty))),
            tail=Empty
          )
        )
      ) {
      let v = match (name, expr) {
        ("string", String(s)) => Constant::String(s)
        ("integer", String(s)) => Integer(s)
        ("number", String(s)) => Number(s)
        ("boolean", Bool(b)) => Boolean(b)
        _ => continue
      }
      break Some(v)
    }
  } else {
    None
  }
}

///|
fn record_to_schema(fields : @list.List[@syntax.FieldDecl]) -> Schema {
  let properties = []
  let required = []
  for field in fields {
    let name = field.name.label
    let description = try! field.doc.content
      .iter()
      .map(line => line.trim_start(char_set="\n\t ").to_string())
      .join("\n")
      .escape()[1:-1].to_string()
    let default = field_default(field.attrs)
    let enums = field_enumerate(field.attrs)
    let (schema, nullable) = match ty_to_schema(field.ty) {
      Nullable(schema) => (schema, true)
      schema => (schema, false)
    }
    match (enums, schema) {
      (Some(_), String(..) as s) => s.enums = enums
      (Some(_), _) =>
        abort(
          "Json schema error (\{field.loc}): currently the enumerate attribute is only allowed on string fields",
        )
      _ => ()
    }
    if !nullable && default is Some(_) {
      abort(
        "Json schema error (\{field.loc}): a field with a default value must be of `T?` type.",
      )
    }
    if !nullable && default is None {
      required.push(name)
    }
    properties.push({ name, type_: schema, default, description })
  }
  Object(properties~, required~)
}

///|
fn mk_string(s : String) -> @syntax.Expr {
  Constant(c=String(s), loc~)
}

///|
fn mk_int(s : String) -> @syntax.Expr {
  Constant(c=Int(s), loc~)
}

///|
fn mk_double(s : String) -> @syntax.Expr {
  Constant(c=Double(s), loc~)
}

///|
fn mk_bool(b : Bool) -> @syntax.Expr {
  Constant(c=Bool(b), loc~)
}

///|
fn mk_array(es : Array[@syntax.Expr]) -> @syntax.Expr {
  Array(exprs=List::from_array(es), loc~)
}

///|
fn constant_to_ast(c : Constant) -> @syntax.Expr {
  match c {
    Number(s) => mk_double(s)
    Integer(s) => mk_int(s)
    String(s) => mk_string(s)
    Boolean(b) => mk_bool(b)
  }
}

///|
fn schema_to_ast(
  schema : Schema,
  nullable? : Bool = false,
  extra_info? : Array[(String, @syntax.Expr)] = [],
) -> @syntax.Expr {

  // Handle null, if the developer wishes to pass `null` explicitly.
  // This should be a rare case.
  //
  // Note:
  // `field : T?`:        represent a field can be omited or present with type `T` in record.
  // `field : Array[E?]`: represent a field must be an array of `E | null`. 
  // 
  // In JSON Schema, if a field is not required in an object, the JSON 
  // `{ field: null }` is invalid in this case.
  // 
  fn maybe_nullable(e : @syntax.Expr) -> @syntax.Expr {
    if nullable {
      Array(exprs=List::from_array([e, mk_string("null")]), loc~)
    } else {
      e
    }
  }

  match schema {
    String(enums~) => {
      let arr = [("type", maybe_nullable(mk_string("string"))), ..extra_info]
      if enums is Some(xs) {
        arr.push(("enum", mk_array(xs.map(constant_to_ast))))
      }
      mk_json_object(arr)
    }
    Boolean =>
      mk_json_object(
        [("type", maybe_nullable(mk_string("boolean"))), ..extra_info],
      )
    Number =>
      mk_json_object(
        [("type", maybe_nullable(mk_string("number"))), ..extra_info],
      )
    Integer =>
      mk_json_object(
        [("type", maybe_nullable(mk_string("integer"))), ..extra_info],
      )
    Array(item~) =>
      mk_json_object(
        [
          ("type", maybe_nullable(mk_string("array"))),
          ("items", schema_to_ast(item)),
          ..extra_info,
        ],
      )
    Nullable(schema) => schema_to_ast(schema, nullable=true, extra_info~)
    Object(properties~, required~) => {
      let properties = properties.map(p => {
        let extra_info = []
        if p.description.trim(char_set="\n\t ") != "" {
          extra_info.push(("description", mk_string(p.description)))
        }
        if p.default is Some(c) {
          extra_info.push(("default", constant_to_ast(c)))
        }
        (p.name, schema_to_ast(p.type_, extra_info~))
      })
      mk_json_object(
        [
          ("type", maybe_nullable(mk_string("object"))),
          ("properties", mk_json_object(properties)),
          ("required", mk_array(required.map(mk_string))),
          ..extra_info,
        ],
      )
    }
  }
}

///|
impl @syntax.IterVisitor for Env with visit_Impl_TopTypeDef(self, decl) {
  if is_derive_pretty(decl.attrs) {
    let expr : @syntax.Expr = match decl.components {
      TupleStruct(_) =>
        abort("Internal error: tuple struct is not supported yet.")
      Alias(_) => abort("Internal error: typealias is not supported yet.")
      Error(_) => abort("Internal error: error type is not supported yet.")
      Extern => abort("Internal error: extern type is not supported yet.")
      Abstract => abort("Internal error: abstract type is not supported yet.")
      Newtype(_) => abort("Internal error: newtype is not supported yet.")
      Variant(_) => abort("Internal error: enum is not supported yet.")
      Record(fields) => {
        let schema = record_to_schema(fields)
        let expr = schema_to_ast(schema)
        expr
      }
    }
    let attr_generated : @attribute.Attribute = {
      parsed: Some(Ident({ qual: Some(NAMESPACE), name: GENERATED })),
      raw: "",
      loc,
    }
    let json_ty : @syntax.Type = Name(
      constr_id=mk_constr("Json"),
      tys=@list.empty(),
      loc~,
    )
    let fun_decl : @syntax.FunDecl = {
      type_name: Some({ name: Ident(name=decl.tycon), is_object: false, loc }),
      name: { name: "get_schema", loc },
      has_error: None,
      is_async: false,
      decl_params: Some(@list.empty()),
      params_loc: loc,
      quantifiers: @list.empty(),
      return_type: Some(json_ty),
      error_type: NoErrorType,
      vis: Default,
      attrs: @list.from_array([attr_generated]),
      doc: @syntax.DocString::empty(),
    }
    let decl_body : @syntax.DeclBody = DeclBody(local_types=empty(), expr~)
    let impl_ = @syntax.TopFuncDef(fun_decl~, decl_body~, loc~)
    self.generated.push(impl_)
  }
}

///|
pub fn derive_json_schema(impls : @syntax.Impls) -> @syntax.Impls {
  let self : Env = { generated: [] }
  impls
  .filter(impl_ => match impl_ {
    TopImpl(attrs~, ..) if is_generated(attrs) => false
    _ => true
  })
  .each(x => self.visit_Impl(x))
  List::from_array(self.generated)
}
