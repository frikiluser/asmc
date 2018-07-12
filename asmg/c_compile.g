
const TYPE_KIND_BASE 0
const TYPE_KIND_POINTER 1
const TYPE_KIND_FUNCTION 2
const TYPE_KIND_ARRAY 3
const TYPE_KIND_STRUCT 4
const TYPE_KIND_UNION 5
const TYPE_KIND_ENUM 6

const TYPE_KIND 0
const TYPE_BASE 4
const TYPE_SIZE 8
const TYPE_LENGTH 12
const TYPE_ARGS 16
const SIZEOF_TYPE 20

fun type_init 0 {
  $type
  @type SIZEOF_TYPE malloc = ;
  type TYPE_ARGS take_addr 4 vector_init = ;
  type ret ;
}

fun type_destroy 1 {
  $type
  @type 0 param = ;
  type TYPE_ARGS take vector_destroy ;
  type free ;
}

fun type_dump 1 {
  $type
  @type 0 param = ;

  $kind
  @kind type TYPE_KIND take = ;
  $base
  @base type TYPE_BASE take = ;

  if kind TYPE_KIND_BASE == {
    "Base type #" 1 platform_log ;
    base itoa 1 platform_log ;
  }

  if kind TYPE_KIND_POINTER == {
    "Pointer type to #" 1 platform_log ;
    base itoa 1 platform_log ;
  }

  if kind TYPE_KIND_FUNCTION == {
    "Function type returning #" 1 platform_log ;
    base itoa 1 platform_log ;
    $args
    @args type TYPE_ARGS take = ;
    if args vector_size 0 == {
      " taking no argument" 1 platform_log ;
    } else {
      " taking arguments" 1 platform_log ;
      $i
      @i 0 = ;
      while i args vector_size < {
        " #" 1 platform_log ;
        args i vector_at itoa 1 platform_log ;
        @i i 1 + = ;
      }
    }
  }

  if kind TYPE_KIND_ARRAY == {
    "Array type of #" 1 platform_log ;
    base itoa 1 platform_log ;
    $length
    @length type TYPE_LENGTH take = ;
    if length 0xffffffff == {
      " of unspecified length" 1 platform_log ;
    } else {
      " of length " 1 platform_log ;
      length itoa 1 platform_log ;
    }
  }

  $size
  @size type TYPE_SIZE take = ;
  if size 0xffffffff == {
    ", of undertermined size" 1 platform_log ;
  } else {
    ", of size " 1 platform_log ;
    size itoa 1 platform_log ;
  }
}

const GLOBAL_TYPE_IDX 0
const GLOBAL_LOC 4
const SIZEOF_GLOBAL 8

fun global_init 0 {
  $global
  @global SIZEOF_GLOBAL malloc = ;
  global ret ;
}

fun global_destroy 1 {
  $global
  @global 0 param = ;
  global free ;
}

fun global_dump 1 {
  $global
  @global 0 param = ;
  "has type #" 1 platform_log ;
  global GLOBAL_TYPE_IDX take itoa 1 platform_log ;
  " and is stored at " 1 platform_log ;
  global GLOBAL_LOC take itoa 1 platform_log ;
}

const CCTX_TYPES 0
const CCTX_TYPENAMES 4
const CCTX_GLOBALS 8
const CCTX_TOKENS 12
const CCTX_TOKENS_POS 16
const CCTX_STAGE 20
const CCTX_CURRENT_LOC 24
const SIZEOF_CCTX 28

fun cctx_init_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TYPES take_addr 4 vector_init = ;
  ctx CCTX_TYPENAMES take_addr map_init = ;
}

fun cctx_init 1 {
  $tokens
  @tokens 0 param = ;

  $ctx
  @ctx SIZEOF_CCTX malloc = ;
  ctx cctx_init_types ;
  ctx CCTX_GLOBALS take_addr map_init = ;
  ctx CCTX_TOKENS take_addr tokens = ;
  ctx CCTX_TOKENS_POS take_addr 0 = ;
  ctx ret ;
}

fun cctx_destroy_types 1 {
  $ctx
  @ctx 0 param = ;

  $types
  @types ctx CCTX_TYPES take = ;
  $i
  @i 0 = ;
  while i types vector_size < {
    types i vector_at type_destroy ;
    @i i 1 + = ;
  }
  types vector_destroy ;

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  typenames map_destroy ;
}

fun cctx_destroy 1 {
  $ctx
  @ctx 0 param = ;

  ctx cctx_destroy_types ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  $i
  @i 0 = ;
  while i globals map_size < {
    if globals i map_has_idx {
      globals i map_at_idx global_destroy ;
    }
    @i i 1 + = ;
  }
  globals map_destroy ;

  ctx free ;
}

fun cctx_reset_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx cctx_destroy_types ;
  ctx cctx_init_types ;
}

fun is_valid_identifier 1 {
  $ident
  @ident 0 param = ;

  #"is_valid_identifier for " 1 platform_log ;
  #ident 1 platform_log ;
  #"\n" 1 platform_log ;

  $len
  @len ident strlen = ;
  if len 0 == { 0 ret ; }
  $i
  @i 0 = ;
  while i len < {
    if ident i + **c get_char_type 3 != { 0 ret ; }
    @i i 1 + = ;
  }
  $first
  @first ident **c = ;
  if first '0' >= first '9' <= && { 0 ret ; }
  #"is_valid_identifier: return true\n" 1 platform_log ;
  1 ret ;
}

fun cctx_get_type 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  ctx CCTX_TYPES take type_idx vector_at ret ;
}

fun cctx_dump_types 1 {
  $ctx
  @ctx 0 param = ;

  $i
  @i 0 = ;
  $types
  @types ctx CCTX_TYPES take = ;
  while i types vector_size < {
    "#" 1 platform_log ;
    i itoa 1 platform_log ;
    ": " 1 platform_log ;
    types i vector_at type_dump ;
    "\n" 1 platform_log ;
    @i i 1 + = ;
  }
}

fun cctx_dump_typenames 1 {
  $ctx
  @ctx 0 param = ;

  $i
  @i 0 = ;
  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  while i typenames map_size < {
    if typenames i map_has_idx {
      "Typename " 1 platform_log ;
      typenames i map_key_at_idx 1 platform_log ;
      ": #" 1 platform_log ;
      typenames i map_at_idx itoa 1 platform_log ;
      "\n" 1 platform_log ;
    }
    @i i 1 + = ;
  }
}

fun cctx_dump_globals 1 {
  $ctx
  @ctx 0 param = ;

  $i
  @i 0 = ;
  $globals
  @globals ctx CCTX_GLOBALS take = ;
  while i globals map_size < {
    if globals i map_has_idx {
      "Global " 1 platform_log ;
      globals i map_key_at_idx 1 platform_log ;
      $global
      @global globals i map_at_idx = ;
      ": " 1 platform_log ;
      global global_dump ;
      "\n" 1 platform_log ;
    }
    @i i 1 + = ;
  }
}

ifun cctx_type_compare 3

fun _cctx_type_compare 3 {
  $ctx
  $t1
  $t2
  @ctx 2 param = ;
  @t1 1 param = ;
  @t2 0 param = ;

  if t1 TYPE_KIND take t2 TYPE_KIND take != { 0 ret ; }
  if t1 TYPE_KIND take TYPE_KIND_BASE == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    1 ret ;
  }
  if t1 TYPE_KIND take TYPE_KIND_POINTER == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    1 ret ;
  }
  if t1 TYPE_KIND take TYPE_KIND_FUNCTION == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    if t1 TYPE_LENGTH take t2 TYPE_LENGTH take != { 0 ret ; }
    $length
    @length t1 TYPE_LENGTH take = ;
    $args1
    $args2
    @args1 t1 TYPE_ARGS take = ;
    @args2 t2 TYPE_ARGS take = ;
    $i
    @i 0 = ;
    while i length < {
      if ctx args1 i vector_at args2 i vector_at cctx_type_compare ! { 0 ret ; }
      @i i 1 + = ;
    }
    1 ret ;
  }
  if t1 TYPE_KIND take TYPE_KIND_ARRAY == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    if t1 TYPE_LENGTH take t2 TYPE_LENGTH take != { 0 ret ; }
    1 ret ;
  }
  0 "_type_compare: not yet implemented" assert_msg ;
}

fun cctx_type_compare 3 {
  $ctx
  $ti1
  $ti2
  @ctx 2 param = ;
  @ti1 1 param = ;
  @ti2 0 param = ;

  if ti1 ti2 == { 1 ret ; }

  $t1
  $t2
  @t1 ctx CCTX_TYPES take ti1 vector_at = ;
  @t2 ctx CCTX_TYPES take ti2 vector_at = ;

  $res
  @res ctx t1 t2 _cctx_type_compare = ;
  if res {
    t1 TYPE_SIZE take t2 TYPE_SIZE take == "type_compare: type are equal, but have different size" assert_msg ;
  }
  res ret ;
}

fun cctx_add_type 2 {
  $ctx
  $type
  @ctx 1 param = ;
  @type 0 param = ;

  $types
  $idx
  @types ctx CCTX_TYPES take = ;
  @idx types vector_size = ;
  types type vector_push_back ;
  idx ret ;
}

fun cctx_get_pointer_type 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_POINTER = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_SIZE take_addr 4 = ;

  ctx type cctx_add_type ret ;
}

fun cctx_get_array_type 3 {
  $ctx
  $type_idx
  $length
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @length 0 param = ;

  $base_type
  @base_type ctx CCTX_TYPES take type_idx vector_at = ;
  base_type TYPE_SIZE take 0xffffffff != "cctx_get_array_type: base type is invalid size" assert_msg ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_ARRAY = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_LENGTH take_addr length = ;
  type TYPE_SIZE take_addr length base_type TYPE_SIZE take * = ;
  # -1 is used when length is not specified
  if length 0xffffffff == {
    type TYPE_SIZE take_addr 0xffffffff = ;
  }

  ctx type cctx_add_type ret ;
}

fun cctx_get_function_type 3 {
  $ctx
  $type_idx
  $args
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @args 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_FUNCTION = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_SIZE take_addr 0xffffffff = ;
  type TYPE_ARGS take vector_destroy ;
  type TYPE_ARGS take_addr args = ;

  ctx type cctx_add_type ret ;
}

const TYPE_VOID 0
const TYPE_CHAR 1
const TYPE_SCHAR 2
const TYPE_UCHAR 3
const TYPE_SHORT 4
const TYPE_INT 5
const TYPE_USHORT 6
const TYPE_UINT 7
const TYPE_CHAR_ARRAY 8

fun cctx_create_basic_type 3 {
  $ctx
  $idx
  $size
  @ctx 2 param = ;
  @idx 1 param = ;
  @size 0 param = ;

  $types
  @types ctx CCTX_TYPES take = ;

  idx types vector_size == "cctx_create_basic_type: error 1" assert_msg ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr size = ;
  types type vector_push_back ;
}

fun cctx_create_basic_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx TYPE_VOID 0xffffffff cctx_create_basic_type ;
  ctx TYPE_CHAR 1 cctx_create_basic_type ;
  ctx TYPE_SCHAR 1 cctx_create_basic_type ;
  ctx TYPE_UCHAR 1 cctx_create_basic_type ;
  ctx TYPE_SHORT 2 cctx_create_basic_type ;
  ctx TYPE_INT 4 cctx_create_basic_type ;
  ctx TYPE_USHORT 2 cctx_create_basic_type ;
  ctx TYPE_UINT 4 cctx_create_basic_type ;

  ctx TYPE_CHAR 0xffffffff cctx_get_array_type TYPE_CHAR_ARRAY == "cctx_create_basic_types: error 1" assert_msg ;
}

fun cctx_get_global 2 {
  $ctx
  $name
  @ctx 1 param = ;
  @name 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  globals name map_has "cctx_get_global: global does not exist" assert_msg ;
  $global
  @global globals name map_at = ;
  global ret ;
}

fun cctx_add_global 4 {
  $ctx
  $name
  $loc
  $type_idx
  @ctx 3 param = ;
  @name 2 param = ;
  @loc 1 param = ;
  @type_idx 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  $present
  @present globals name map_has = ;
  $global
  if present {
    @global globals name map_at = ;
    ctx global GLOBAL_TYPE_IDX take type_idx cctx_type_compare "cctx_add_global: types do not match" assert_msg ;
  } else {
    ctx CCTX_STAGE take 0 == "cctx_add_global: error 1" assert_msg ;
    @global global_init = ;
    global GLOBAL_TYPE_IDX take_addr type_idx = ;
    global GLOBAL_LOC take_addr loc = ;
    globals name global map_set ;
  }

  if ctx CCTX_STAGE take 0 == {
    global GLOBAL_LOC take_addr 0xffffffff = ;
    present ! "cctx_add_global: error 4" assert_msg ;
  } else {
    present "cctx_add_global: error 2" assert_msg ;
  }

  if ctx CCTX_STAGE take 1 == {
    global GLOBAL_LOC take 0xffffffff == "cctx_add_global: error 5" assert_msg ;
    global GLOBAL_LOC take_addr loc = ;
  }

  if ctx CCTX_STAGE take 2 == {
    global GLOBAL_LOC take loc == "cctx_add_global: error 3" assert_msg ;
  }
}

fun cctx_add_global_funct 4 {
  $ctx
  $name
  $loc
  $type_idx
  @ctx 3 param = ;
  @name 2 param = ;
  @loc 1 param = ;
  @type_idx 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  $present
  @present globals name map_has = ;
  $global
  if present {
    @global globals name map_at = ;
    ctx global GLOBAL_TYPE_IDX take type_idx cctx_type_compare "cctx_add_global_funct: function types do not match" assert_msg ;
  } else {
    ctx CCTX_STAGE take 0 == "cctx_add_global_funct: error 1" assert_msg ;
    @global global_init = ;
    global GLOBAL_TYPE_IDX take_addr type_idx = ;
    global GLOBAL_LOC take_addr loc = ;
    globals name global map_set ;
  }

  if ctx CCTX_STAGE take 0 == {
    global GLOBAL_LOC take_addr 0xffffffff = ;
  } else {
    present "cctx_add_global_funct: error 2" assert_msg ;
  }

  if ctx CCTX_STAGE take 1 == {
    if loc 0xffffffff != {
      global GLOBAL_LOC take 0xffffffff == "cctx_add_global_funct: function is defined more than once" assert_msg ;
      global GLOBAL_LOC take_addr loc = ;
    }
  }

  if ctx CCTX_STAGE take 2 == {
    if loc 0xffffffff != {
      global GLOBAL_LOC take loc == "cctx_add_global_funct: error 3" assert_msg ;
    }
  }
}

fun cctx_is_eof 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TOKENS_POS take ctx CCTX_TOKENS take vector_size == ret ;
}

fun cctx_get_token 1 {
  $ctx
  @ctx 0 param = ;

  if ctx CCTX_TOKENS_POS take ctx CCTX_TOKENS take vector_size == {
    0 ret ;
  } else {
    $tok
    @tok ctx CCTX_TOKENS take ctx CCTX_TOKENS_POS take vector_at = ;
    ctx CCTX_TOKENS_POS take_addr ctx CCTX_TOKENS_POS take 1 + = ;
    tok ret ;
  }
}

fun cctx_give_back_token 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TOKENS_POS take 0 > "cctx_give_back_token: error 1" assert_msg ;
  ctx CCTX_TOKENS_POS take_addr ctx CCTX_TOKENS_POS take 1 - = ;
}

fun cctx_save_token_pos 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TOKENS_POS take ret ;
}

fun cctx_restore_token_pos 2 {
  $ctx
  $pos
  @ctx 1 param = ;
  @pos 0 param = ;

  ctx CCTX_TOKENS_POS take_addr pos = ;
}

fun cctx_get_token_or_fail 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token = ;
  tok 0 != "cctx_get_token_or_fail: unexpected end-of-file" assert_msg ;
  tok ret ;
}

fun cctx_go_to_matching 3 {
  $ctx
  $open
  $close
  @ctx 2 param = ;
  @open 1 param = ;
  @close 0 param = ;

  $level
  @level 1 = ;
  while level 0 > {
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok open strcmp 0 == {
      @level level 1 + = ;
    }
    if tok close strcmp 0 == {
      @level level 1 - = ;
    }
  }
}

fun cctx_print_token_pos 1 {
  $ctx
  @ctx 0 param = ;

  "Token pos: " 1 platform_log ;
  ctx CCTX_TOKENS_POS take itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun cctx_emit 2 {
  $ctx
  $byte
  @ctx 1 param = ;
  @byte 0 param = ;

  if ctx CCTX_STAGE take 2 == {
    ctx CCTX_CURRENT_LOC take byte =c ;
  }
  ctx CCTX_CURRENT_LOC take_addr ctx CCTX_CURRENT_LOC take 1 + = ;
}

fun cctx_emit16 2 {
  $ctx
  $word
  @ctx 1 param = ;
  @word 0 param = ;

  ctx word cctx_emit ;
  ctx word 8 >> cctx_emit ;
}

fun cctx_emit32 2 {
  $ctx
  $dword
  @ctx 1 param = ;
  @dword 0 param = ;

  ctx dword cctx_emit16 ;
  ctx dword 16 >> cctx_emit16 ;
}

fun cctx_emit_zeros 2 {
  $ctx
  $num
  @ctx 1 param = ;
  @num 0 param = ;

  $i
  @i 0 = ;
  while i num < {
    ctx 0 cctx_emit ;
    @i i 1 + = ;
  }
}

fun cctx_parse_type 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;

  if tok "void" strcmp 0 == { TYPE_VOID ret ; }
  if tok "char" strcmp 0 == { TYPE_CHAR ret ; }
  if tok "short" strcmp 0 == { TYPE_SHORT ret ; }
  if tok "int" strcmp 0 == { TYPE_INT ret ; }
  if tok "signed" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    if tok "char" strcmp 0 == { TYPE_SCHAR ret ; }
    if tok "short" strcmp 0 == { TYPE_SHORT ret ; }
    if tok "int" strcmp 0 == { TYPE_INT ret ; }
    0 "cctx_parse_type: unexpected token after signed" assert_msg ;
  }
  if tok "unsigned" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    if tok "char" strcmp 0 == { TYPE_UCHAR ret ; }
    if tok "short" strcmp 0 == { TYPE_USHORT ret ; }
    if tok "int" strcmp 0 == { TYPE_UINT ret ; }
    0 "cctx_parse_type: unexpected token after unsigned" assert_msg ;
  }

  if tok "struct" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    0 "cctx_parse_type: unimplemented" assert_msg ;
  }
  if tok "enum" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    0 "cctx_parse_type: unimplemented" assert_msg ;
  }
  if tok "union" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    0 "cctx_parse_type: unimplemented" assert_msg ;
  }

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  if typenames tok map_has {
    $idx
    @idx typenames tok map_at = ;
    idx ret ;
  } else {
    ctx cctx_give_back_token ;
    0xffffffff ret ;
  }
}

ifun cctx_parse_declarator 5

fun _cctx_parse_function_arguments 2 {
  $ctx
  $ret_arg_names
  @ctx 1 param = ;
  @ret_arg_names 0 param = ;

  $args
  @args 4 vector_init = ;
  while 1 {
    $type_idx
    @type_idx ctx cctx_parse_type = ;
    if type_idx 0xffffffff == {
      $tok
      @tok ctx cctx_get_token_or_fail = ;
      tok ")" strcmp 0 == "_cctx_parse_function_arguments: ) or type expected" assert_msg ;
      args vector_size 0 == "_cctx_parse_function_arguments: unexpected )" assert_msg ;
      args ret ;
    }
    $name
    $actual_type_idx
    if ctx type_idx @actual_type_idx @name 0 cctx_parse_declarator ! {
      @actual_type_idx type_idx = ;
    }
    args actual_type_idx vector_push_back ;
    if ret_arg_names 0 != {
      ret_arg_names name vector_push_back ;
    }
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok ")" strcmp 0 == {
      args ret ;
    }
    tok "," strcmp 0 == "_cctx_parse_function_arguments: ) or , expected" assert_msg ;
  }
}

fun _cctx_parse_declarator 5 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  $ret_arg_names
  @ctx 4 param = ;
  @type_idx 3 param = ;
  @ret_type_idx 2 param = ;
  @ret_name 1 param = ;
  @ret_arg_names 0 param = ;

  #"_cctx_parse_declarator: entering\n" 1 platform_log ;
  #ctx cctx_print_token_pos ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;
  $processed
  @processed 0 = ;

  #"_cctx_parse_declarator: token is " 1 platform_log ;
  #tok 1 platform_log ;
  #"\n" 1 platform_log ;

  # Parse pointer declaration
  if tok "*" strcmp 0 == {
    @type_idx ctx type_idx cctx_get_pointer_type = ;
    if ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator ! {
      ret_type_idx type_idx = ;
    }
    @processed 1 = ;
  }

  # Parse function declaration and grouping parantheses
  if tok "(" strcmp 0 == {
    # Here the first problem is decide whether this is a function or
    # grouping parenthesis; if immediately after there is a type or a
    # closing parenthesis, we are in the first case; otherwise, we are
    # in the second case.
    $pos
    @pos ctx cctx_save_token_pos = ;
    $type
    @type ctx cctx_parse_type = ;
    ctx pos cctx_restore_token_pos ;
    $is_funct
    @is_funct 0 = ;
    if type 0xffffffff != {
      @is_funct 1 = ;
    }
    @tok ctx cctx_get_token_or_fail = ;
    if tok ")" strcmp 0 == {
      @is_funct 1 = ;
    }

    # Restore the content of tok, so that the program does not get
    # captured in later branches
    @tok "(" = ;

    ctx cctx_give_back_token ;
    if is_funct {
      # Function parenthesis
      $args
      @args ctx ret_arg_names _cctx_parse_function_arguments = ;
      if ctx type_idx ret_type_idx ret_name 0 _cctx_parse_declarator {
        @type_idx ret_type_idx ** = ;
      }
      ret_type_idx ctx type_idx args cctx_get_function_type = ;
    } else {
      # Grouping parenthesis
      $inside_pos
      $outside_pos
      $end_pos
      @inside_pos ctx cctx_save_token_pos = ;
      ctx "(" ")" cctx_go_to_matching ;
      @outside_pos ctx cctx_save_token_pos = ;
      if ctx type_idx ret_type_idx ret_name 0 _cctx_parse_declarator {
        @type_idx ret_type_idx ** = ;
      }
      @end_pos ctx cctx_save_token_pos = ;
      ctx inside_pos cctx_restore_token_pos ;
      ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator "_cctx_parse_declarator: invalid syntax 1" assert_msg ;
      @tok ctx cctx_get_token_or_fail = ;
      tok ")" strcmp 0 == "_cctx_parse_declarator: error 1" assert_msg ;
      outside_pos ctx cctx_save_token_pos == "_cctx_parse_declarator: invalid syntax 2" assert_msg ;
      ctx end_pos cctx_restore_token_pos ;
    }
    @processed 1 = ;
  }

  # Parse array declaration
  if tok "[" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    $length
    if tok "]" strcmp 0 == {
      @length 0xffffffff = ;
    } else {
      # FIXME Implement proper formula parsing
      @length tok atoi = ;
      @tok ctx cctx_get_token_or_fail = ;
    }
    tok "]" strcmp 0 == "_cctx_parse_declarator: expected ] after array subscript" assert_msg ;
    if ctx type_idx ret_type_idx ret_name 0 _cctx_parse_declarator {
      @type_idx ret_type_idx ** = ;
    }
    ret_type_idx ctx type_idx length cctx_get_array_type = ;
    @processed 1 = ;
  }

  # Parse the actual declarator identifier
  if tok is_valid_identifier {
    if ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator ! {
      ret_type_idx type_idx = ;
    }
    ret_name ** 0 == "_cctx_parse_declarator: more than one identifier found" assert_msg ;
    ret_name tok = ;
    @processed 1 = ;
  }

  if processed ! {
    ctx cctx_give_back_token ;
    #"_cctx_parse_declarator: failed\n" 1 platform_log ;
    0 ret ;
  }

  #"_cctx_parse_declarator: success\n" 1 platform_log ;
  1 ret ;
}

fun cctx_parse_declarator 5 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  $ret_arg_names
  @ctx 4 param = ;
  @type_idx 3 param = ;
  @ret_type_idx 2 param = ;
  @ret_name 1 param = ;
  @ret_arg_names 0 param = ;

  ret_name 0 = ;
  ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator ret ;
}

fun cctx_type_footprint 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  $type
  @type ctx CCTX_TYPES take type_idx vector_at = ;
  $size
  @size type TYPE_SIZE take = ;
  size 0xffffffff != "cctx_type_footprint: type cannot be instantiated" assert_msg ;
  size 1 - 3 | 1 + ret ;
}

const STACK_ELEM_NAME 0
const STACK_ELEM_TYPE_IDX 4
const STACK_ELEM_LOC 8
const SIZEOF_STACK_ELEM 12

fun stack_elem_init 0 {
  $elem
  @elem SIZEOF_STACK_ELEM malloc = ;
  elem ret ;
}

fun stack_elem_destroy 1 {
  $elem
  @elem 0 param = ;
  elem free ;
}

const LCTX_STACK 0
const SIZEOF_LCTX 4

fun lctx_init 0 {
  $lctx
  @lctx SIZEOF_LCTX malloc = ;
  lctx LCTX_STACK take_addr 4 vector_init = ;
  lctx ret ;
}

fun lctx_destroy 1 {
  $lctx
  @lctx 0 param = ;

  $stack
  @stack lctx LCTX_STACK take = ;
  $i
  @i 0 = ;
  while i stack vector_size < {
    stack i vector_at stack_elem_destroy ;
    @i i 1 + = ;
  }

  lctx LCTX_STACK take vector_destroy ;
  lctx free ;
}

fun lctx_get_variable 2 {
  $lctx
  $name
  @lctx 1 param = ;
  @name 0 param = ;

  # Begin scanning the stack from the end, so that inner variables
  # mask outer ones
  $stack
  @stack lctx LCTX_STACK take = ;
  $i
  @i stack vector_size 1 - = ;
  while i 0 >= {
    $elem
    @elem stack i vector_at = ;
    if elem STACK_ELEM_NAME take name strcmp 0 == {
      elem ret ;
    }
    @i i 1 - = ;
  }

  0 ret ;
}

fun lctx_stack_pos 1 {
  $lctx
  @lctx 0 param = ;

  $stack
  @stack lctx LCTX_STACK take = ;
  stack stack vector_size 1 - vector_at STACK_ELEM_LOC take ret ;
}

fun lctx_save_status 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;
  lctx LCTX_STACK take vector_size ret ;
}

fun lctx_restore_status 3 {
  $lctx
  $ctx
  $status
  @lctx 2 param = ;
  @ctx 1 param = ;
  @status 0 param = ;

  $current_pos
  @current_pos lctx lctx_stack_pos = ;
  $stack
  @stack lctx LCTX_STACK take = ;
  status stack vector_size <= "lctx_restore_status: error 1" assert_msg ;
  $new_pos
  @new_pos stack status 1 - vector_at STACK_ELEM_LOC take = ;
  $rewind
  @rewind new_pos current_pos - = ;
  rewind 0 >= "lctx_restore_status: error 2" assert_msg ;

  # add esp, rewind
  ctx 0x81 cctx_emit ;
  ctx 0xc4 cctx_emit ;
  ctx rewind cctx_emit32 ;

  # Drop enough stack elements in excess
  while stack vector_size status > {
    $elem
    @elem stack vector_pop_back = ;
    elem stack_elem_destroy ;
  }
}

fun lctx_push_var 3 {
  $lctx
  $ctx
  $type_idx
  $name
  @lctx 3 param = ;
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @name 0 param = ;

  $footprint
  @footprint ctx type_idx cctx_type_footprint = ;
  $new_pos
  @new_pos lctx lctx_stack_pos footprint - = ;

  $elem
  @elem stack_elem_init = ;
  elem STACK_ELEM_NAME take_addr name = ;
  elem STACK_ELEM_TYPE_IDX take_addr type_idx = ;
  elem STACK_ELEM_LOC take_addr new_pos = ;
  lctx LCTX_STACK take elem vector_push_back ;

  # sub esp, footprint
  ctx 0x81 cctx_emit ;
  ctx 0xec cctx_emit ;
  ctx footprint cctx_emit32 ;
}

fun lctx_prime_stack 3 {
  $lctx
  $ctx
  $type_idx
  $arg_names
  @lctx 3 param = ;
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @arg_names 0 param = ;

  $type
  @type ctx type_idx cctx_get_type = ;
  type TYPE_KIND take TYPE_KIND_FUNCTION == "lctx_prime_stack: type is not a function" assert_msg ;
  $args
  @args type TYPE_ARGS take = ;
  args vector_size arg_names vector_size == "lctx_prime_stack: error 1" assert_msg ;
  $stack
  @stack lctx LCTX_STACK take = ;

  $i
  @i 0 = ;
  $total_footprint
  @total_footprint 0 = ;
  while i args vector_size < {
    @total_footprint total_footprint ctx args i vector_at cctx_type_footprint + = ;
    @i i 1 + = ;
  }
  $loc
  @loc total_footprint 8 + = ;
  @i args vector_size 1 - = ;
  while i 0 >= {
    $this_type_idx
    @this_type_idx args i vector_at = ;
    $name
    @name arg_names i vector_at = ;
    name 0 != "lctx_prime_stack: name cannot be empty" assert_msg ;
    @loc loc ctx this_type_idx cctx_type_footprint - = ;
    $elem
    @elem stack_elem_init = ;
    elem STACK_ELEM_NAME take_addr name = ;
    elem STACK_ELEM_TYPE_IDX take_addr this_type_idx = ;
    elem STACK_ELEM_LOC take_addr loc = ;
    stack elem vector_push_back ;
    @i i 1 - = ;
  }
  loc 8 == "lctx_prime_stack: error 2" assert_msg ;

  # Add a fictious element to mark the beginning of local variables
  $elem
  @elem stack_elem_init = ;
  elem STACK_ELEM_NAME take_addr "" = ;
  elem STACK_ELEM_TYPE_IDX take_addr 0 = ;
  elem STACK_ELEM_LOC take_addr 0 = ;
  stack elem vector_push_back ;
}

fun lctx_gen_prologue 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;

  # push ebp; mov ebp, esp
  ctx 0x55 cctx_emit ;
  ctx 0x89 cctx_emit ;
  ctx 0xe5 cctx_emit ;
}

fun lctx_gen_epilogue 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;

  # add esp, stack_pos
  ctx 0x81 cctx_emit ;
  ctx 0xc4 cctx_emit ;
  ctx 0 lctx lctx_stack_pos - cctx_emit32 ;

  # pop ebp; ret
  ctx 0x5d cctx_emit ;
  ctx 0xc3 cctx_emit ;
}

ifun ast_eval_type 3

fun ast_arith_conv 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $type1
  $type2
  @type1 ast AST_LEFT take ctx lctx ast_eval_type = ;
  @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;

  if type1 TYPE_CHAR ==
     type1 TYPE_SCHAR == ||
     type1 TYPE_UCHAR == ||
     type1 TYPE_SHORT == ||
     type1 TYPE_INT == ||
     type1 TYPE_USHORT == || {
    @type1 TYPE_INT = ;
  } else {
    type1 TYPE_UINT == "ast_arith_conv: left is not an integer type" assert_msg ;
  }

  if type2 TYPE_CHAR ==
     type2 TYPE_SCHAR == ||
     type2 TYPE_UCHAR == ||
     type2 TYPE_SHORT == ||
     type2 TYPE_INT == ||
     type2 TYPE_USHORT == || {
    @type2 TYPE_INT = ;
  } else {
    type2 TYPE_UINT == "ast_arith_conv: right is not an integer type" assert_msg ;
  }

  if type1 TYPE_UINT == type2 TYPE_UINT == || {
    TYPE_UINT ret ;
  } else {
    TYPE_INT ret ;
  }
}

fun ast_eval_type 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  if ast AST_TYPE_IDX take 0xffffffff != {
    ast AST_TYPE_IDX take ret ;
  }

  $name
  @name ast AST_NAME take = ;
  $type_idx
  if ast AST_TYPE take 0 == {
    # Operand
    if name is_valid_identifier {
      # Search in local stack and among globals
      $elem
      @elem lctx name lctx_get_variable = ;
      if elem {
        @type_idx elem STACK_ELEM_TYPE_IDX take = ;
      } else {
        $global
        @global ctx name cctx_get_global = ;
        @type_idx global GLOBAL_TYPE_IDX take = ;
      }
    } else {
      if name **c '\"' == {
        @type_idx TYPE_CHAR_ARRAY = ;
      } else {
        if name **c '\'' == {
          @type_idx TYPE_INT = ;
        } else {
          @type_idx TYPE_INT = ;
        }
      }
    }
  } else {
    # Operator
    $processed
    @processed 0 = ;

    if name "*" strcmp 0 ==
       name "/" strcmp 0 == ||
       name "%" strcmp 0 == ||
       name "+" strcmp 0 == ||
       name "-" strcmp 0 == ||
       name "<" strcmp 0 == ||
       name ">" strcmp 0 == ||
       name "<=" strcmp 0 == ||
       name ">=" strcmp 0 == ||
       name "==" strcmp 0 == ||
       name "!=" strcmp 0 == ||
       name "&" strcmp 0 == ||
       name "^" strcmp 0 == ||
       name "|" strcmp 0 == || {
      @type_idx ast ctx lctx ast_arith_conv = ;
      @processed 1 = ;
    }

    processed "ast_eval_type: not implemented" assert_msg ;
  }

  ast AST_TYPE_IDX take_addr type_idx = ;
  type_idx ret ;
}

fun ast_push_addr 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;
  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;
  if ast AST_TYPE take 0 == {
    # Operand
    if name is_valid_identifier {
      # Search in local stack and among globals
      $elem
      @elem lctx name lctx_get_variable = ;
      if elem {
        # lea eax, [ebp+loc]; push eax
        ctx 0x8d cctx_emit ;
        ctx 0x85 cctx_emit ;
        ctx elem STACK_ELEM_LOC take cctx_emit32 ;
        ctx 0x50 cctx_emit ;
      } else {
        $global
        @global ctx name cctx_get_global = ;
        # push loc
        ctx 0x68 cctx_emit ;
        ctx global GLOBAL_LOC take cctx_emit32 ;
      }
    } else {
      0 "ast_push_addr: cannot take the address of an immediate" assert_msg ;
    }
  } else {
    # Operator
    $processed
    @processed 0 = ;

    processed "ast_push_value: not implemented" assert_msg ;
  }
}

fun ast_int_convert 5 {
  $ast
  $ctx
  $lctx
  $from_idx
  $to_idx
  @ast 4 param = ;
  @ctx 3 param = ;
  @lctx 2 param = ;
  @from_idx 1 param = ;
  @to_idx 0 param = ;

  to_idx TYPE_INT == to_idx TYPE_UINT == || "ast_int_convert: unsupported target type" assert_msg ;

  if from_idx TYPE_CHAR == from_idx TYPE_SCHAR == || {
    # movsx eax, al
    ctx 0x0f cctx_emit ;
    ctx 0xbe cctx_emit ;
    ctx 0xc0 cctx_emit ;
  } else {
    if from_idx TYPE_UCHAR == {
      # movzx eax, al
      ctx 0x0f cctx_emit ;
      ctx 0xb6 cctx_emit ;
      ctx 0xc0 cctx_emit ;
    } else {
      if from_idx TYPE_SHORT == {
        # movsx eax, ax
        ctx 0x0f cctx_emit ;
        ctx 0xbf cctx_emit ;
        ctx 0xc0 cctx_emit ;
      } else {
        if from_idx TYPE_USHORT == {
          # movzx eax, ax
          ctx 0x0f cctx_emit ;
          ctx 0xb7 cctx_emit ;
          ctx 0xc0 cctx_emit ;
        } else {
          from_idx TYPE_INT == from_idx TYPE_UINT == || "ast_int_convert: unsupported source type" assert_msg ;
        }
      }
    }
  }
}

ifun ast_push_value 3

fun ast_push_value_arith 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $type1
  $type2
  $type_idx
  $name
  @type1 ast AST_LEFT take ctx lctx ast_eval_type = ;
  @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;
  @type_idx ast ctx lctx ast_eval_type = ;
  @name ast AST_NAME take = ;

  # Sanity check: both operands must fit in 4 bytes
  ctx type1 cctx_type_footprint 4 == "ast_push_value_arith: error 1" assert_msg ;
  ctx type2 cctx_type_footprint 4 == "ast_push_value_arith: error 2" assert_msg ;

  # Recursively evalute both operands
  ast AST_LEFT take ctx lctx ast_push_value ;
  ast AST_RIGHT take ctx lctx ast_push_value ;

  # Pop right result, promote it and store in ECX
  # pop eax; ast_int_convert; mov ecx, eax
  ctx 0x58 cctx_emit ;
  ast ctx lctx type2 type_idx ast_int_convert ;
  ctx 0x89 cctx_emit ;
  ctx 0xc1 cctx_emit ;

  # Pop left result, promote it and store in EAX
  # pop eax, ast_int_convert
  ctx 0x58 cctx_emit ;
  ast ctx lctx type1 type_idx ast_int_convert ;

  # Invoke the operation specific operation
  $processed
  @processed 0 = ;

  if name "+" strcmp 0 == {
    # add eax, ecx
    ctx 0x01 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "-" strcmp 0 == {
    # sub eax, ecx
    ctx 0x29 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "&" strcmp 0 == {
    # and eax, ecx
    ctx 0x21 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "|" strcmp 0 == {
    # or eax, ecx
    ctx 0x09 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "^" strcmp 0 == {
    # xor eax, ecx
    ctx 0x01 cctx_emit ;
    ctx 0x31 cctx_emit ;
    @processed 1 = ;
  }

  if name "*" strcmp 0 == type_idx TYPE_UINT == && {
    # mul ecx
    ctx 0xf7 cctx_emit ;
    ctx 0xe1 cctx_emit ;
    @processed 1 = ;
  }

  if name "*" strcmp 0 == type_idx TYPE_INT == && {
    # imul ecx
    ctx 0xf7 cctx_emit ;
    ctx 0xe9 cctx_emit ;
    @processed 1 = ;
  }

  if name "/" strcmp 0 == type_idx TYPE_UINT == && {
    # xor edx, edx; div ecx
    ctx 0x31 cctx_emit ;
    ctx 0xd2 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf1 cctx_emit ;
    @processed 1 = ;
  }

  if name "/" strcmp 0 == type_idx TYPE_INT == && {
    # cdq; idiv ecx
    ctx 0x99 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf9 cctx_emit ;
    @processed 1 = ;
  }

  if name "%" strcmp 0 == type_idx TYPE_UINT == && {
    # xor edx, edx; div ecx; mov eax, edx
    ctx 0x31 cctx_emit ;
    ctx 0xd2 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf1 cctx_emit ;
    ctx 0x89 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    @processed 1 = ;
  }

  if name "%" strcmp 0 == type_idx TYPE_INT == && {
    # cdq; idiv ecx; mov eax, edx
    ctx 0x99 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf9 cctx_emit ;
    ctx 0x89 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    @processed 1 = ;
  }

  if name "==" strcmp 0 == {
    # cmp eax, edx; xor eax, eax; sete al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x94 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "!=" strcmp 0 == {
    # cmp eax, edx; xor eax, eax; setne al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x95 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, edx; xor eax, eax; setb al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x92 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<=" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, edx; xor eax, eax; setbe al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x96 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, edx; xor eax, eax; seta al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x97 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">=" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, edx; xor eax, eax; setae al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x93 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, edx; xor eax, eax; setl al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x9c cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<=" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, edx; xor eax, eax; setle al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x9e cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, edx; xor eax, eax; setg al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x9f cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">=" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, edx; xor eax, eax; setge al
    ctx 0x39 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x31 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x9d cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  processed "ast_push_value_arith: not implemented" assert_msg ;

  # Push result stored in EAX
  # push eax
  ctx 0x50 cctx_emit ;
}

fun cctx_gen_push_data 2 {
  $ctx
  $size
  @ctx 1 param = ;
  @size 0 param = ;

  size 4 % 0 == "cctx_gen_push_data: size is not multiple of 4" assert_msg ;

  if size 0 == {
    ret ;
  }

  $i
  @i size 4 - = ;
  while i 0 >= {
    # push [eax+off]
    ctx 0xff cctx_emit ;
    ctx 0xb0 cctx_emit ;
    ctx i cctx_emit32 ;
    @i i 4 - = ;
  }
}

fun ast_push_value 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;
  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;
  if ast AST_TYPE take 0 == {
    # Operand
    if name is_valid_identifier {
      # Push the address
      ast ctx lctx ast_push_addr ;
      # pop eax
      ctx 0x58 cctx_emit ;
      ctx ctx type_idx cctx_type_footprint cctx_gen_push_data ;
    } else {
      $value
      if name **c '\"' == {
        0 assert ;
        
      } else {
        if name **c '\'' == {
          0 assert ;
          
        } else {
          @value name atoi = ;
        }
      }

      # push value
      ctx 0x68 cctx_emit ;
      ctx value cctx_emit32 ;
    }
  } else {
    # Operator
    $processed
    @processed 0 = ;

    if name "*" strcmp 0 ==
       name "/" strcmp 0 == ||
       name "%" strcmp 0 == ||
       name "+" strcmp 0 == ||
       name "-" strcmp 0 == ||
       name "<" strcmp 0 == ||
       name ">" strcmp 0 == ||
       name "<=" strcmp 0 == ||
       name ">=" strcmp 0 == ||
       name "==" strcmp 0 == ||
       name "!=" strcmp 0 == ||
       name "&" strcmp 0 == ||
       name "^" strcmp 0 == ||
       name "|" strcmp 0 == || {
      ast ctx lctx ast_push_value_arith ;
      @processed 1 = ;
    }

    processed "ast_push_value: not implemented" assert_msg ;
  }
}

fun ast_eval 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  # First push value
  ast ctx lctx ast_push_value ;

  # Then pop and discard it
  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;
  $footprint
  @footprint ctx type_idx cctx_type_footprint = ;

  # add esp, footprint
  ctx 0x81 cctx_emit ;
  ctx 0xc4 cctx_emit ;
  ctx footprint cctx_emit32 ;
}

fun cctx_compile_block 2 {
  $ctx
  $lctx
  @ctx 1 param = ;
  @lctx 0 param = ;

  $saved_pos
  @saved_pos lctx ctx lctx_save_status = ;

  while 1 {
    $processed
    @processed 0 = ;
    $tok
    @tok ctx cctx_get_token_or_fail = ;

    # Check if we found the closing brace
    if tok "}" strcmp 0 == processed ! && {
      lctx ctx saved_pos lctx_restore_status ;
      @processed 1 = ;
      ret ;
    }

    # Check if this is a return statement
    if tok "return" strcmp 0 == processed ! && {
      lctx ctx lctx_gen_epilogue ;
      @processed 1 = ;
    }

    if processed ! {
      ctx cctx_give_back_token ;

      # Try to parse a type, in which case we have a variable declaration
      $type_idx
      @type_idx ctx cctx_parse_type = ;
      if type_idx 0xffffffff != {
        # There is a type, so we have a variable declaration
        $actual_type_idx
        $name
        ctx type_idx @actual_type_idx @name 0 cctx_parse_declarator "cctx_compile_block: error 1" assert_msg ;
        name 0 != "cctx_compile_block: cannot instantiate variable without name" assert_msg ;
        lctx ctx actual_type_idx name lctx_push_var ;
      } else {
        # No type, so this is an expression
        $ast
        # Bad hack to fix ast_parse interface
        ctx cctx_give_back_token ;
        @ast ctx CCTX_TOKENS take ctx CCTX_TOKENS_POS take_addr ";" ast_parse = ;
        ast ctx lctx ast_eval_type ;
        ast ast_dump ;
        ast ctx lctx ast_eval ;
        ast ast_destroy ;
      }
    }

    # Expect and consume the semicolon
    @tok ctx cctx_get_token_or_fail = ;
    tok ";" strcmp 0 == "cctx_compile_block: ; expected" assert_msg ;
  }
}

fun cctx_compile_function 3 {
  $ctx
  $type_idx
  $arg_names
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @arg_names 0 param = ;

  # Costruct the local context
  $lctx
  @lctx lctx_init = ;
  lctx ctx type_idx arg_names lctx_prime_stack ;

  lctx ctx lctx_gen_prologue ;
  ctx lctx cctx_compile_block ;
  lctx ctx lctx_gen_epilogue ;

  lctx lctx_destroy ;
}

fun cctx_compile_line 1 {
  $ctx
  @ctx 0 param = ;

  $type_idx
  @type_idx ctx cctx_parse_type = ;
  type_idx 0xffffffff != "cctx_compile: type expected" assert_msg ;
  $cont
  @cont 1 = ;
  while cont {
    $actual_type_idx
    $name
    $arg_names
    @arg_names 4 vector_init = ;
    ctx type_idx @actual_type_idx @name arg_names cctx_parse_declarator "cctx_compile_line: error 1" assert_msg ;
    $type
    @type ctx CCTX_TYPES take actual_type_idx vector_at = ;
    name 0 != "cctx_compile_line: cannot instantiate variable without name" assert_msg ;
    if type TYPE_KIND take TYPE_KIND_FUNCTION == {
      # If it is a function, check if it has a body
      $tok
      @tok ctx cctx_get_token_or_fail = ;
      if tok "{" strcmp 0 == {
        # There is the body, register the global and compile the body
        ctx name ctx CCTX_CURRENT_LOC take actual_type_idx cctx_add_global_funct ;
        ctx actual_type_idx arg_names cctx_compile_function ;
        @cont 0 = ;
      } else {
        # No body, register the global with a fictious location
        ctx cctx_give_back_token ;
        ctx name 0xffffffff actual_type_idx cctx_add_global_funct ;
      }
    } else {
      # If it is anything else, register it and allocate its size
      ctx name ctx CCTX_CURRENT_LOC take actual_type_idx cctx_add_global ;
      ctx ctx actual_type_idx cctx_type_footprint cctx_emit_zeros ;
    }
    arg_names vector_destroy ;

    if cont {
      $tok
      @tok ctx cctx_get_token_or_fail = ;
      if tok ";" strcmp 0 == {
        @cont 0 = ;
      } else {
        tok "," strcmp 0 == "cctx_compile_line: comma expected" assert_msg ;
      }
    }
  }
}

fun cctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_STAGE take_addr 0 = ;
  $start_loc
  @start_loc 0 = ;
  $size
  while ctx CCTX_STAGE take 3 < {
    "Compilation stage " 1 platform_log ;
    ctx CCTX_STAGE take 1 + itoa 1 platform_log ;
    ctx CCTX_CURRENT_LOC take_addr start_loc = ;
    ctx CCTX_TOKENS_POS take_addr 0 = ;
    ctx cctx_reset_types ;
    ctx cctx_create_basic_types ;
    while ctx cctx_is_eof ! {
      ctx cctx_compile_line ;
    }
    "\n" 1 platform_log ;
    if ctx CCTX_STAGE take 0 == {
      @size ctx CCTX_CURRENT_LOC take start_loc - = ;
      @start_loc size platform_allocate = ;
    } else {
      ctx CCTX_CURRENT_LOC take start_loc - size == "cctx_compile: error 1" assert_msg ;
    }
    ctx CCTX_STAGE take_addr ctx CCTX_STAGE take 1 + = ;
  }
  "Compiled program has size " 1 platform_log ;
  size itoa 1 platform_log ;
  " and starts at " 1 platform_log ;
  start_loc itoa 1 platform_log ;
  "\n" 1 platform_log ;
  "Compiled dump:\n" 1 platform_log ;
  start_loc size dump_mem ;
  "\n" 1 platform_log ;
}

fun parse_c 1 {
  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx 0 param preproc_file ;
  @tokens tokens remove_whites = ;
  "Finished preprocessing\n" 1 platform_log ;
  $i
  @i 0 = ;
  while i tokens vector_size < {
    $tok
    @tok tokens i vector_at = ;
    if tok **c '\n' == {
      "NL" 1 platform_log ;
    } else {
      tok 1 platform_log ;
    }
    "#" 1 platform_log ;
    @i i 1 + = ;
  }
  "\n" 1 platform_log ;

  # Compilation
  $cctx
  @cctx tokens cctx_init = ;
  cctx cctx_compile ;

  # Debug output
  "TYPES TABLE\n" 1 platform_log ;
  cctx cctx_dump_types ;
  "TYPE NAMES TABLE\n" 1 platform_log ;
  cctx cctx_dump_typenames ;
  "GLOBALS TABLE\n" 1 platform_log ;
  cctx cctx_dump_globals ;

  # Try to execute the code
  "Executing compiled code...\n" 1 platform_log ;
  $main_global
  @main_global cctx "main" cctx_get_global = ;
  $main_addr
  @main_addr main_global GLOBAL_LOC take = ;
  $arg
  @arg "_main" = ;
  $res
  @res @arg 1 main_addr \2 = ;
  "It returned " 1 platform_log ;
  res itoa 1 platform_log ;
  "\n" 1 platform_log ;

  # Cleanup
  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
