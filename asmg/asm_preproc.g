
fun get_char_type 1 {
  $x
  @x 0 param = ;
  if x '\n' == { 1 ret ; }
  if x '\t' == x ' ' == || { 2 ret ; }
  if x '0' >= x '9' <= && x 'a' >= x 'z' <= && || x 'A' >= x 'Z' <= && || x '_' == || { 3 ret ; }
  4 ret ;
}

const ASMCTX_FDIN 0
const ASMCTX_READ_CHAR 4
const ASMCTX_CHAR_GIVEN_BACK 8
const ASMCTX_SYMBOLS 12
const ASMCTX_STAGE 16
const ASMCTX_CURRENT_LOC 20
const SIZEOF_ASMCTX 24

fun asmctx_init 0 {
  $ptr
  @ptr SIZEOF_ASMCTX malloc = ;
  ptr ASMCTX_SYMBOLS take_addr map_init = ;
  ptr ret ;
}

fun asmctx_destroy 1 {
  $ptr
  @ptr 0 param = ;
  ptr ASMCTX_SYMBOLS take map_destroy ;
  ptr free ;
}

fun asmctx_emit 2 {
  $ctx
  $byte
  @ctx 1 param = ;
  @byte 0 param = ;

  if ctx ASMCTX_STAGE take 2 == {
    ctx ASMCTX_CURRENT_LOC take byte =c ;
  }
  ctx ASMCTX_CURRENT_LOC take_addr ctx ASMCTX_CURRENT_LOC take 1 + = ;
}

fun asmctx_emit16 2 {
  $ctx
  $word
  @ctx 1 param = ;
  @word 0 param = ;

  ctx word asmctx_emit ;
  ctx word 8 >> asmctx_emit ;
}

fun asmctx_emit32 2 {
  $ctx
  $dword
  @ctx 1 param = ;
  @dword 0 param = ;

  ctx dword asmctx_emit16 ;
  ctx dword 16 >> asmctx_emit16 ;
}

fun asmctx_add_symbol 3 {
  $ctx
  $name
  $value
  @ctx 2 param = ;
  @name 1 param = ;
  @value 0 param = ;

  $syms
  @syms ctx ASMCTX_SYMBOLS take = ;

  if ctx ASMCTX_STAGE take 1 == {
    syms name map_has ! "asmctx_add_symbol: symbol already defined" assert_msg ;
    syms name value map_set ;
  }
  if ctx ASMCTX_STAGE take 2 == {
    syms name map_has "asmctx_add_symbol: error 1" assert_msg ;
    syms name map_at value == "asmctx_add_symbol: error 2" assert_msg ;
  }
}

fun asmctx_get_symbol 2 {
  $ctx
  $name
  @ctx 1 param = ;
  @name 0 param = ;

  $syms
  @syms ctx ASMCTX_SYMBOLS take = ;

  if ctx ASMCTX_STAGE take 2 == {
    syms name map_has "asmctx_add_symbol: symbol undefined" assert_msg ;
    syms name map_at ret ;
  } else {
    0 ret ;
  }
}

fun asmctx_set_fd 2 {
  $ptr
  $fd
  @ptr 1 param = ;
  @fd 0 param = ;
  ptr ASMCTX_CHAR_GIVEN_BACK take_addr 0 = ;
  ptr ASMCTX_FDIN take_addr fd = ;
}

# fun asmctx_set_starting_loc 2 {
#   $ptr
#   $loc
#   @ptr 1 param = ;
#   @loc 0 param = ;
#   ptr ASMCTX_CURRENT_LOC take_addr loc = ;
# }

fun asmctx_give_back_char 1 {
  $ctx
  @ctx 0 param = ;
  ctx ASMCTX_CHAR_GIVEN_BACK take ! "Character already given back" assert_msg ;
  ctx ASMCTX_CHAR_GIVEN_BACK take_addr 1 = ;
}

fun asmctx_get_char 1 {
  $ctx
  @ctx 0 param = ;
  if ctx ASMCTX_CHAR_GIVEN_BACK take {
    ctx ASMCTX_CHAR_GIVEN_BACK take_addr 0 = ;
  } else {
    ctx ASMCTX_READ_CHAR take_addr ctx ASMCTX_FDIN take platform_read_char = ;
  }
  ctx ASMCTX_READ_CHAR take ret ;
}

fun asmctx_get_token 1 {
  $ctx
  @ctx 0 param = ;
  $token_buf
  $token_buf_len
  @token_buf_len 32 = ;
  @token_buf token_buf_len malloc = ;
  $state
  @state 0 = ;
  $token_type
  $token_len
  @token_len 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    $c
    @c ctx asmctx_get_char = ;
    @cont c 0xffffffff != = ;
    if cont {
      $save_char
      @save_char 0 = ;
      $type
      @type c get_char_type = ;
      $enter_state
      @enter_state state = ;
      # Normal code
      if enter_state 0 == {
        @save_char 1 = ;
      }
      # Comment
      if enter_state 1 == {
        if c '\n' == {
          token_buf '\n' =c ;
          @token_len 1 = ;
          @state 0 = ;
          @cont 0 = ;
        }
      }
      # String
      if enter_state 2 == {
        @save_char 1 = ;
        #if c '\\' == {
        #  @state 3 = ;
        #}
        if c '\'' == {
          @state 0 = ;
          @cont 0 = ;
        }
      }
      # String after backslash
      if enter_state 3 == {
        @save_char 1 = ;
        @state 2 = ;
      }
      token_buf token_len + c =c ;
      if save_char {
        if token_len 0 == {
          if type 2 != {
            @token_len token_len 1 + = ;
            @token_type type = ;
            if c '\'' == {
              @state 2 = ;
              @token_type 0 = ;
            }
            if c ';' == {
              @state 1 = ;
              @token_type 0 = ;
            }
            if token_type 1 == {
              @cont 0 = ;
            }
            if token_type 4 == {
              @cont 0 = ;
            }
          }
        } else {
          if token_type type == token_type 0 == || {
            @token_len token_len 1 + = ;
          } else {
            ctx asmctx_give_back_char ;
            @cont 0 = ;
          }
        }
      }
      if token_len 1 + token_buf_len >= {
        @token_buf_len token_buf_len 2 * = ;
        @token_buf token_buf_len token_buf realloc = ;
      }
    }
  }
  if token_type 2 == {
    token_buf ' ' =c ;
    @token_len 1 = ;
  }
  token_buf token_len + 0 =c ;
  token_buf ret ;
}
