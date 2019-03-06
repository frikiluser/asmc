# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2019 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

fun mm0_is_digit 1 {
  $c
  @c 0 param = ;

  '0' c <= c '9' <= && ret ;
}

fun mm0_is_alpha 1 {
  $c
  @c 0 param = ;

  'a' c <= c 'z' <= && 'A' c <= c 'Z' <= && || ret ;
}

fun mm0_is_white 1 {
  $c
  @c 0 param = ;

  c ' ' == c '\n' == || c '\r' == || c '\t' == || ret ;
}

const MM0TOK_TYPE 0
const MM0TOK_VALUE 4
const SIZEOF_MM0TOK 8

const MM0TOK_TYPE_SYMBOL 1
const MM0TOK_TYPE_IDENT 2
const MM0TOK_TYPE_NUMBER 3
const MM0TOK_TYPE_MATH 4

const MM0TOK_SYMB_STAR 1
const MM0TOK_SYMB_DOT 2
const MM0TOK_SYMB_COLON 3
const MM0TOK_SYMB_SEMICOLON 4
const MM0TOK_SYMB_OPEN 5
const MM0TOK_SYMB_CLOSED 6
const MM0TOK_SYMB_ARROW 7
const MM0TOK_SYMB_OPENBR 8
const MM0TOK_SYMB_CLOSEDBR 9
const MM0TOK_SYMB_ASSIGN 10

fun mm0tok_init 2 {
  $type
  $value
  @type 1 param = ;
  @value 0 param = ;

  $tok
  @tok SIZEOF_MM0TOK malloc = ;
  tok MM0TOK_TYPE take_addr type = ;
  tok MM0TOK_VALUE take_addr value = ;

  tok ret ;
}

fun mm0tok_destroy 1 {
  $tok
  @tok 0 param = ;

  $type
  @type tok MM0TOK_TYPE take = ;
  if type MM0TOK_TYPE_IDENT == type MM0TOK_TYPE_MATH == || {
    tok MM0TOK_VALUE take free ;
  }
  tok free ;
}

fun mm0tok_cmp_value 3 {
  $tok
  $type
  $value
  @tok 2 param = ;
  @type 1 param = ;
  @value 0 param = ;

  if tok MM0TOK_TYPE take type != { 0 ret ; }

  if type MM0TOK_TYPE_SYMBOL == {
    tok MM0TOK_VALUE take value == ret ;
  }

  if type MM0TOK_TYPE_IDENT == {
    tok MM0TOK_VALUE take value strcmp 0 == ret ;
  }

  if type MM0TOK_TYPE_NUMBER == {
    tok MM0TOK_VALUE take value == ret ;
  }

  if type MM0TOK_TYPE_MATH == {
    tok MM0TOK_VALUE take value strcmp 0 == ret ;
  }

  0 "mm0tok_expect_type_value: illegal token type" assert_msg ;
}

fun mm0tok_dump 1 {
  $tok
  @tok 0 param = ;

  $type
  $value
  @type tok MM0TOK_TYPE take = ;
  @value tok MM0TOK_VALUE take = ;

  if type MM0TOK_TYPE_SYMBOL == {
    if value MM0TOK_SYMB_STAR == { "STAR" log ; ret ; }
    if value MM0TOK_SYMB_DOT == { "DOT" log ; ret ; }
    if value MM0TOK_SYMB_COLON == { "COLON" log ; ret ; }
    if value MM0TOK_SYMB_SEMICOLON == { "SEMICOLON" log ; ret ; }
    if value MM0TOK_SYMB_OPEN == { "OPEN" log ; ret ; }
    if value MM0TOK_SYMB_CLOSED == { "CLOSED" log ; ret ; }
    if value MM0TOK_SYMB_ARROW == { "ARROW" log ; ret ; }
    if value MM0TOK_SYMB_OPENBR == { "OPENBR" log ; ret ; }
    if value MM0TOK_SYMB_CLOSEDBR == { "CLOSEDBR" log ; ret ; }
    if value MM0TOK_SYMB_ASSIGN == { "ASSIGN" log ; ret ; }
  }

  if type MM0TOK_TYPE_IDENT == {
    value log ;
    ret ;
  }

  if type MM0TOK_TYPE_NUMBER == {
    value itoa log ;
    ret ;
  }

  if type MM0TOK_TYPE_MATH == {
    "$" log ;
    value log ;
    "$" log ;
    ret ;
  }
}

const MM0LEXER_FILENAME 0
const MM0LEXER_FD 4
const MM0LEXER_UNREAD 8
const SIZEOF_MM0LEXER 12

fun mm0lexer_init 1 {
  $filename
  @filename 0 param = ;

  $fd
  @fd filename vfs_open = ;
  if fd ! {
    0 ret ;
  }

  $lexer
  @lexer SIZEOF_MM0LEXER malloc = ;
  lexer MM0LEXER_FILENAME take_addr filename = ;
  lexer MM0LEXER_FD take_addr fd = ;
  lexer MM0LEXER_UNREAD take_addr 0 = ;

  lexer ret ;
}

fun mm0lexer_destroy 1 {
  $lexer
  @lexer 0 param = ;

  lexer MM0LEXER_FD take vfs_close ;
  lexer free ;
}

fun mm0lexer_read 1 {
  $lexer
  @lexer 0 param = ;

  $c
  @c lexer MM0LEXER_UNREAD take = ;
  if c {
    lexer MM0LEXER_UNREAD take_addr 0 = ;
    c ret ;
  } else {
    lexer MM0LEXER_FD take vfs_read ret ;
  }
}

fun mm0lexer_unread 2 {
  $lexer
  $c
  @lexer 1 param = ;
  @c 0 param = ;

  lexer MM0LEXER_UNREAD take ! "mm0lexer_unread: unread buffer already used" assert_msg ;
  lexer MM0LEXER_UNREAD take_addr c = ;
}

fun mm0lexer_read_skip 1 {
  $lexer
  @lexer 0 param = ;

  while 1 {
    $c
    @c lexer mm0lexer_read = ;
    # Check comment
    if c '-' == {
      @c lexer mm0lexer_read = ;
      c '-' == "mm0lexer_read_skip: invalid single dash" assert_msg ;
      while c '\n' != {
        @c lexer mm0lexer_read = ;
      }
    } else {
     if c mm0_is_white ! {
        c ret ;
      }
    }
  }
}

fun mm0lexer_get_token_or_eof_ 1 {
  $lexer
  @lexer 0 param = ;

  $c
  @c lexer mm0lexer_read_skip = ;

  # End of file
  if c 0xffffffff == {
    0 ret ;
  }

  # Symbol token
  if c '*' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_STAR mm0tok_init ret ;
  }
  if c '.' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_DOT mm0tok_init ret ;
  }
  if c ':' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_COLON mm0tok_init ret ;
  }
  if c ';' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_SEMICOLON mm0tok_init ret ;
  }
  if c '(' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_OPEN mm0tok_init ret ;
  }
  if c ')' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_CLOSED mm0tok_init ret ;
  }
  if c '>' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_ARROW mm0tok_init ret ;
  }
  if c '{' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_OPENBR mm0tok_init ret ;
  }
  if c '}' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_CLOSEDBR mm0tok_init ret ;
  }
  if c '=' == {
    MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_ASSIGN mm0tok_init ret ;
  }

  # Number token
  if c mm0_is_digit {
    $zero
    @zero c '0' == = ;
    $value
    @value c '0' - = ;
    @c lexer mm0lexer_read = ;
    while c mm0_is_digit {
      zero ! "mm0lexer_get_token_or_eof_: invalid 0 prefix in number token" assert_msg ;
      @value value 10 * c '0' - + = ;
      @c lexer mm0lexer_read = ;
    }
    c mm0_is_alpha ! "mm0lexer_get_token_or_eof_: unexpected alphabetic character in number token" assert_msg ;
    lexer c mm0lexer_unread ;
    MM0TOK_TYPE_NUMBER value mm0tok_init ret ;
  }

  # Identifier token
  if c mm0_is_alpha c '_' == || {
    $size
    $cap
    $value
    @size 0 = ;
    @cap 4 = ;
    @value cap malloc = ;
    while c mm0_is_digit c mm0_is_alpha || c '_' == || c '-' == || {
      # +1 to be sure there is space for the terminator
      if size 1 + cap >= {
        @cap cap 2 * = ;
        @value cap value realloc = ;
      }
      value size + c =c ;
      @size size 1 + = ;
      @c lexer mm0lexer_read = ;
    }
    lexer c mm0lexer_unread ;
    value size + '\0' =c ;
    MM0TOK_TYPE_IDENT value mm0tok_init ret ;
  }

  # Math token
  if c '$' == {
    $size
    $cap
    $value
    @size 0 = ;
    @cap 4 = ;
    @value cap malloc = ;
    @c lexer mm0lexer_read = ;
    $cont
    @cont 1 = ;
    while c '$' != {
      # +1 to be sure there is space for the terminator
      if size 1 + cap >= {
        @cap cap 2 * = ;
        @value cap value realloc = ;
      }
      if c mm0_is_white {
        @c ' ' = ;
      }
      value size + c =c ;
      @size size 1 + = ;
      @c lexer mm0lexer_read = ;
    }
    value size + '\0' =c ;
    MM0TOK_TYPE_MATH value mm0tok_init ret ;
  }

  0 "mm0lexer_get_token_or_eof_: invalid character in input file" assert_msg ;
}

fun mm0lexer_get_token_or_eof 1 {
  $lexer
  @lexer 0 param = ;

  $token
  @token lexer mm0lexer_get_token_or_eof_ = ;

  if token {
    token mm0tok_dump ;
    " " log ;
  } else {
    "EOF" log ;
  }

  token ret ;
}

fun mm0lexer_get_token 1 {
  $lexer
  @lexer 0 param = ;

  $token
  @token lexer mm0lexer_get_token_or_eof = ;
  token "mm0lexer_get_token: unexpected end of file" assert_msg ;

  token ret ;
}

fun mm0lexer_get_token_type 2 {
  $lexer
  $type
  @lexer 1 param = ;
  @type 0 param = ;

  $tok
  @tok lexer mm0lexer_get_token = ;
  tok MM0TOK_TYPE take type == "mm0lexer_get_token_type: wrong token type" assert_msg ;

  tok ret ;
}

fun mm0lexer_expect 3 {
  $lexer
  $type
  $value
  @lexer 2 param = ;
  @type 1 param = ;
  @value 0 param = ;

  $tok
  @tok lexer mm0lexer_get_token = ;
  tok type value mm0tok_cmp_value "mm0lexer_expect: illegal token" assert_msg ;
  tok mm0tok_destroy ;
}

const MM0SORT_PURE 0
const MM0SORT_STRICT 4
const MM0SORT_PROVABLE 8
const MM0SORT_NONEMPTY 12
const SIZEOF_MM0SORT 16

fun mm0sort_init 0 {
  $sort
  @sort SIZEOF_MM0SORT malloc = ;

  sort MM0SORT_PURE take_addr 0 = ;
  sort MM0SORT_STRICT take_addr 0 = ;
  sort MM0SORT_PROVABLE take_addr 0 = ;
  sort MM0SORT_NONEMPTY take_addr 0 = ;

  sort ret ;
}

fun mm0sort_destroy 1 {
  $sort
  @sort 0 param = ;

  sort free ;
}

const MM0TH_LEXER 0
const MM0TH_LEVEL 4
const MM0TH_SORTS 8
const SIZEOF_MM0TH 12

fun mm0th_init 0 {
  $theory
  @theory SIZEOF_MM0TH malloc = ;

  theory MM0TH_LEVEL take_addr 0 = ;
  theory MM0TH_SORTS take_addr map_init = ;

  theory ret ;
}

fun mm0th_sorts_destroy_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  value mm0sort_destroy ;
}

fun mm0th_destroy 1 {
  $theory
  @theory 0 param = ;

  theory MM0TH_SORTS take @mm0th_sorts_destroy_closure 0 map_foreach ;
  theory MM0TH_SORTS take map_destroy ;

  theory free ;
}

fun mm0_parse_sort 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(sort-stmt) " log ;

  $sort
  @sort mm0sort_init = ;

  # Read sort properties
  $cont
  @cont 1 = ;
  while cont {
    $ok
    @ok 0 = ;
    if tok MM0TOK_TYPE_IDENT "pure" mm0tok_cmp_value { @ok 1 = ; sort MM0SORT_PURE take_addr 1 = ; }
    if tok MM0TOK_TYPE_IDENT "strict" mm0tok_cmp_value { @ok 1 = ; sort MM0SORT_STRICT take_addr 1 = ; }
    if tok MM0TOK_TYPE_IDENT "provable" mm0tok_cmp_value { @ok 1 = ; sort MM0SORT_PROVABLE take_addr 1 = ; }
    if tok MM0TOK_TYPE_IDENT "nonempty" mm0tok_cmp_value { @ok 1 = ; sort MM0SORT_NONEMPTY take_addr 1 = ; }
    if tok MM0TOK_TYPE_IDENT "sort" mm0tok_cmp_value { @ok 1 = ; @cont 0 = ; }
    ok "mm0_parse_sort: parsing failed" assert_msg ;
    tok mm0tok_destroy ;
    @tok lexer MM0TOK_TYPE_IDENT mm0lexer_get_token_type = ;
  }

  # Register the sort
  $sorts
  @sorts theory MM0TH_SORTS take = ;
  $value
  @value tok MM0TOK_VALUE take = ;
  sorts value map_has ! "mm0_parse_sort: sort already exists" assert_msg ;
  sorts value sort map_set ;
  tok mm0tok_destroy ;

  # Expect semicolon
  lexer MM0TOK_TYPE_SYMBOL MM0TOK_SYMB_SEMICOLON mm0lexer_expect ;
}

fun mm0_parse_var 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(var-stmt) " log ;

  # Discard tokens up to the semicolon
  $cont
  @cont 1 = ;
  tok mm0tok_destroy ;
  while cont {
    @tok lexer mm0lexer_get_token = ;
    if tok MM0TOK_TYPE take MM0TOK_TYPE_SYMBOL ==
       tok MM0TOK_VALUE take MM0TOK_SYMB_SEMICOLON == && {
      @cont 0 = ;
    }
    tok mm0tok_destroy ;
  }
}

fun mm0_parse_term 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(term-stmt) " log ;

  # Discard tokens up to the semicolon
  $cont
  @cont 1 = ;
  tok mm0tok_destroy ;
  while cont {
    @tok lexer mm0lexer_get_token = ;
    if tok MM0TOK_TYPE take MM0TOK_TYPE_SYMBOL ==
       tok MM0TOK_VALUE take MM0TOK_SYMB_SEMICOLON == && {
      @cont 0 = ;
    }
    tok mm0tok_destroy ;
  }
}

fun mm0_parse_assert 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(assert-stmt) " log ;

  # Discard tokens up to the semicolon
  $cont
  @cont 1 = ;
  tok mm0tok_destroy ;
  while cont {
    @tok lexer mm0lexer_get_token = ;
    if tok MM0TOK_TYPE take MM0TOK_TYPE_SYMBOL ==
       tok MM0TOK_VALUE take MM0TOK_SYMB_SEMICOLON == && {
      @cont 0 = ;
    }
    tok mm0tok_destroy ;
  }
}

fun mm0_parse_def 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(def-stmt) " log ;

  # Discard tokens up to the open brace
  $cont
  @cont 1 = ;
  tok mm0tok_destroy ;
  while cont {
    @tok lexer mm0lexer_get_token = ;
    if tok MM0TOK_TYPE take MM0TOK_TYPE_SYMBOL ==
       tok MM0TOK_VALUE take MM0TOK_SYMB_OPENBR == && {
      theory MM0TH_LEVEL take_addr theory MM0TH_LEVEL take 1 + = ;
      @cont 0 = ;
    }
    tok mm0tok_destroy ;
  }
}

fun mm0_parse_notation 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(notation-stmt) " log ;

  # Discard tokens up to the semicolon
  $cont
  @cont 1 = ;
  tok mm0tok_destroy ;
  while cont {
    @tok lexer mm0lexer_get_token = ;
    if tok MM0TOK_TYPE take MM0TOK_TYPE_SYMBOL ==
       tok MM0TOK_VALUE take MM0TOK_SYMB_SEMICOLON == && {
      @cont 0 = ;
    }
    tok mm0tok_destroy ;
  }
}

fun mm0_parse_output 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $lexer
  @lexer theory MM0TH_LEXER take = ;

  "(output-stmt) " log ;

  # Discard tokens up to the semicolon
  $cont
  @cont 1 = ;
  tok mm0tok_destroy ;
  while cont {
    @tok lexer mm0lexer_get_token = ;
    if tok MM0TOK_TYPE take MM0TOK_TYPE_SYMBOL ==
       tok MM0TOK_VALUE take MM0TOK_SYMB_SEMICOLON == && {
      @cont 0 = ;
    }
    tok mm0tok_destroy ;
  }
}

fun mm0_parse_statement 2 {
  $theory
  $tok
  @theory 1 param = ;
  @tok 0 param = ;

  $value
  @value tok MM0TOK_VALUE take = ;

  if value "pure" strcmp 0 ==
     value "strict" strcmp 0 == ||
     value "provable" strcmp 0 == ||
     value "nonempty" strcmp 0 == ||
     value "sort" strcmp 0 == || {
    theory tok mm0_parse_sort ;
    ret ;
  }
  if value "var" strcmp 0 == {
    theory tok mm0_parse_var ;
    ret ;
  }
  if value "term" strcmp 0 == {
    theory tok mm0_parse_term ;
    ret ;
  }
  if value "axiom" strcmp 0 ==
     value "theorem" strcmp 0 == || {
    theory tok mm0_parse_assert ;
    ret ;
  }
  if value "def" strcmp 0 == {
    theory tok mm0_parse_def ;
    ret ;
  }
  if value "infixl" strcmp 0 ==
     value "infixr" strcmp 0 == ||
     value "prefix" strcmp 0 == ||
     value "coercion" strcmp 0 == ||
     value "notation" strcmp 0 == || {
    theory tok mm0_parse_notation ;
    ret ;
  }
  if value "output" strcmp 0 == {
    theory tok mm0_parse_output ;
    ret ;
  }

  0 "mm0_parse_statement: invalid statement" assert_msg ;
}

fun mm0_parse 1 {
  $lexer
  @lexer 0 param = ;

  $theory
  @theory mm0th_init = ;

  theory MM0TH_LEXER take_addr lexer = ;

  while 1 {
    $tok
    @tok lexer mm0lexer_get_token_or_eof = ;
    if tok ! {
      theory MM0TH_LEVEL take 0 == "mm0_parse: unmatched braces" assert_msg ;
      theory ret ;
    }

    $type
    $value
    @type tok MM0TOK_TYPE take = ;
    @value tok MM0TOK_VALUE take = ;
    if type MM0TOK_TYPE_SYMBOL == {
      if value MM0TOK_SYMB_OPENBR == {
        theory MM0TH_LEVEL take_addr theory MM0TH_LEVEL take 1 + = ;
      } else {
        value MM0TOK_SYMB_CLOSEDBR == "mm0_parse: invalid symbol" assert_msg ;
        theory MM0TH_LEVEL take 0 > "mm0_parse: invalid block closing" assert_msg ;
        theory MM0TH_LEVEL take_addr theory MM0TH_LEVEL take 1 - = ;
      }
      tok mm0tok_destroy ;
    } else {
      type MM0TOK_TYPE_IDENT == "mm0_parse: invalid token type" assert_msg ;
      theory tok mm0_parse_statement ;
    }
  }
}

fun mm0_process 1 {
  $filename
  @filename 0 param = ;

  $lexer
  @lexer filename mm0lexer_init = ;

  $theory
  "Parsing MM0 theory: " log ;
  @theory lexer mm0_parse = ;
  "\n" log ;

  # TODO: verify theory

  # Free resources
  theory mm0th_destroy ;
  lexer mm0lexer_destroy ;
}
