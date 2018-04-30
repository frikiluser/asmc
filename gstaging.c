
#include "platform.h"

#define MAX_TOKEN_LEN 128
#define STACK_LEN 1024
#define SYMBOL_TABLE_LEN 1024
#define WRITE_LABEL_BUF_LEN 128

#define TEMP_VAR "__temp"

int read_fd;

int token_given_back;
int token_len;
char token_buf[MAX_TOKEN_LEN];
char buf2[MAX_TOKEN_LEN];

int block_depth;
int stack_depth;
int temp_depth;
int current_loc;
int ret_depth;
int symbol_num;
int stage;
int label_num;

char stack_vars[MAX_TOKEN_LEN * STACK_LEN];

char symbol_names[MAX_TOKEN_LEN * SYMBOL_TABLE_LEN];
int symbol_locs[SYMBOL_TABLE_LEN];
int symbol_arities[SYMBOL_TABLE_LEN];

char write_label_buf[WRITE_LABEL_BUF_LEN];

int atoi(char*);
int sprintf(char *str, const char *format, ...);

void assert(int cond);
void assert(int cond) {
  if (!cond) {
    platform_panic();
  }
}

void strcpy(char *d, const char *s);
void strcpy(char *d, const char *s) {
  while (1) {
    *d = *s;
    if (*s == '\0') {
      return;
    }
    d++;
    s++;
  }
}

int strlen(const char *s);
int strlen(const char *s) {
  const char *s2 = s;
  while (*s2 != '\0') {
    s2++;
  }
  return s2 - s;
}

int strcmp(const char *s1, const char *s2);
int strcmp(const char *s1, const char *s2) {
  while (1) {
    if (*s1 < *s2) {
      return -1;
    }
    if (*s1 > *s2) {
      return 1;
    }
    if (*s1 == '\0') {
      return 0;
    }
    s1++;
    s2++;
  }
}

void emit(char c);
void emit(char c) {
  if (stage == 1) {
    platform_write_char(1, c);
  }
  current_loc++;
}

void emit32(int x);
void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

void emit_str(char *x, int len) {
  while (len > 0) {
    emit(*x);
    x++;
    len--;
  }
}

int gen_label() {
  return label_num++;
}

char *write_label(int id) {
  sprintf(write_label_buf, "__label%d", id);
  return write_label_buf;
}

int find_symbol(char *name) {
  int i;
  for (i = 0; i < symbol_num; i++) {
    if (strcmp(name, symbol_names + i * MAX_TOKEN_LEN) == 0) {
      break;
    }
  }
  if (i == symbol_num) {
    i = SYMBOL_TABLE_LEN;
  }
  return i;
}

void add_symbol(char *name, int loc, int arity) {
  int len = strlen(name);
  assert(len > 0);
  assert(len < MAX_TOKEN_LEN);
  if (stage == 0) {
    assert(find_symbol(name) == SYMBOL_TABLE_LEN);
    assert(symbol_num < SYMBOL_TABLE_LEN);
    symbol_locs[symbol_num] = loc;
    symbol_arities[symbol_num] = arity;
    strcpy(symbol_names + symbol_num * MAX_TOKEN_LEN, name);
    symbol_num = symbol_num + 1;
  } else if (stage == 1) {
    int idx = find_symbol(name);
    assert(idx < symbol_num);
    assert(symbol_locs[idx] == loc);
    assert(symbol_arities[idx] == arity);
  } else {
    assert(0);
  }
}

int get_symbol(char *name, int *arity) {
  if (stage == 1 || arity != 0) {
    int pos = find_symbol(name);
    assert(pos != SYMBOL_TABLE_LEN);
    if (arity != 0) {
      *arity = symbol_arities[pos];
    }
    return symbol_locs[pos];
  } else {
    return 0;
  }
}

void push_var(char *var_name, int temp) {
  int len = strlen(var_name);
  assert(len > 0);
  assert(len < MAX_TOKEN_LEN);
  assert(stack_depth < STACK_LEN);
  strcpy(stack_vars + stack_depth * MAX_TOKEN_LEN, var_name);
  stack_depth++;
  if (temp) {
    temp_depth++;
  } else {
    assert(temp_depth == 0);
  }
}

void pop_var(int temp) {
  assert(stack_depth > 0);
  stack_depth--;
  if (temp) {
    assert(temp_depth > 0);
    temp_depth--;
  }
}

int pop_temps() {
  while (temp_depth > 0) {
    pop_var(1);
  }
}

int find_in_stack(char *var_name) {
  int i;
  for (i = 0; i < stack_depth; i++) {
    if (strcmp(var_name, stack_vars + (stack_depth - 1 - i) * MAX_TOKEN_LEN) == 0) {
      return i;
    }
  }
  return -1;
}

int is_whitespace(char x) {
  return x == ' ' || x == '\t' || x == '\n';
}

char *get_token() {
  if (token_given_back) {
    token_given_back = 0;
    return token_buf;
  }
  int x;
  token_len = 0;
  int state = 0;
  while (1) {
    x = platform_read_char(read_fd);
    if (x == -1) {
      break;
    }
    int save_char = 0;
    if (state == 0) {
      if (is_whitespace(x)) {
        if (token_len > 0) {
          break;
        }
      } else if ((char) x == '#') {
        state = 1;
      } else {
        if ((char) x == '"') {
          state = 2;
        }
        save_char = 1;
      }
    } else if (state == 1) {
      if ((char) x == '\n') {
        state = 0;
        if (token_len > 0) {
          break;
        }
      }
    } else if (state == 2) {
      if ((char) x == '"') {
        state = 0;
      } else if ((char) x == '\\') {
        state = 3;
      }
      save_char = 1;
    } else if (state == 3) {
      state = 2;
      save_char = 1;
    } else {
      assert(0);
    }
    if (save_char) {
      token_buf[token_len++] = (char) x;
    }
  }
  token_buf[token_len] = '\0';
  return token_buf;
}

void give_back_token() {
  assert(!token_given_back);
  token_given_back = 1;
}

void expect(char *x) {
  char *tok = get_token();
  assert(strcmp(tok, x) == 0);
}

char escaped(char x) {
  if (x == 'n') { return '\n'; }
  if (x == 't') { return '\t'; }
  if (x == '0') { return '\0'; }
  if (x == '\\') { return '\\'; }
  if (x == '\'') { return '\''; }
  if (x == '"') { return '"'; }
  return 0;
}

void emit_escaped_string(char *s) {
  assert(*s == '"');
  s++;
  while (1) {
    assert(*s != 0);
    if (*s == '"') {
      s++;
      assert(*s == 0);
      return;
    }
    if (*s == '\\') {
      s++;
      assert(*s != 0);
      emit(escaped(*s));
    } else {
      emit(*s);
    }
    s++;
  }
}

int decode_number(const char *operand, unsigned int *num);
int decode_number(const char *operand, unsigned int *num) {
  *num = 0;
  if (*operand == '\'') {
    if (operand[1] == '\\') {
      *num = escaped(operand[2]);
      assert(operand[3] == 0);
    } else {
      *num = operand[1];
      assert(operand[2] == 0);
    }
    return 1;
  }
  int is_decimal = 1;
  int digit_seen = 0;
  if (operand[0] == '0' && operand[1] == 'x') {
    operand += 2;
    is_decimal = 0;
  }
  while (1) {
    if (operand[0] == '\0') {
      if (digit_seen) {
        return 1;
      } else {
        return 0;
      }
    }
    digit_seen = 1;
    if (is_decimal) {
      *num *= 10;
    } else {
      *num *= 16;
    }
    if ('0' <= operand[0] && operand[0] <= '9') {
      *num += operand[0] - '0';
    } else if (!is_decimal && 'a' <= operand[0] && operand[0] <= 'f') {
      *num += operand[0] - 'a' + 10;
    } else {
      return 0;
    }
    operand++;
  }
}

int compute_rel(int addr) {
  return addr - current_loc - 4;
}

void push_expr(char *tok, int want_addr) {
  // Try to interpret as a number
  int val;
  if (decode_number(tok, &val)) {
    assert(!want_addr);
    push_var(TEMP_VAR, 1);
    emit(0x68);  // push val
    emit32(val);
    return;
  }
  // Look for the name in the stack
  int pos = find_in_stack(tok);
  if (pos != -1) {
    if (want_addr) {
      push_var(TEMP_VAR, 1);
      emit_str("\x8d\x84\x24", 3);  // lea eax, [esp+pos]
      emit32(4 * pos);
      emit(0x50);  // push eax
    } else {
      push_var(TEMP_VAR, 1);
      emit_str("\xff\xb4\x24", 3);  // push [esp+pos]
      emit32(4 * pos);
    }
  } else {
    int arity;
    int loc = get_symbol(tok, &arity);
    if (arity == -2) {
      assert(!want_addr);
    }
    if (want_addr || arity == -2) {
      push_var(TEMP_VAR, 1);
      emit(0x68);  // push loc
      emit32(loc);
    } else {
      if (arity == -1) {
        push_var(TEMP_VAR, 1);
        emit(0xb8);  // mov eax, loc
        emit32(loc);
        emit_str("\xff\x30", 2);  // push [eax]
      } else {
        emit(0xe8);  // call rel
        emit32(compute_rel(loc));
        emit_str("\x81\xc4", 2);  // add esp, ...
        emit32(4 * arity);
        while (arity > 0) {
          pop_var(1);
          arity--;
        }
        push_var(TEMP_VAR, 1);
        emit(0x50);  // push eax
      }
    }
  }
}

void parse_block() {
  block_depth++;
  int saved_stack_depth = stack_depth;
  expect("{");
  while (1) {
    char *tok = get_token();
    assert(*tok != '\0');
    if (strcmp(tok, "}") == 0) {
      break;
    } else if (strcmp(tok, ";") == 0) {
      emit_str("\x81\xc4", 2);  // add esp, ...
      emit32(4 * temp_depth);
      pop_temps();
    } else if (strcmp(tok, "ret") == 0) {
      if (temp_depth > 0) {
        emit(0x58);  // pop eax
        pop_var(1);
      }
      emit_str("\x81\xc4", 2);  // add esp, ..
      emit32(4 * stack_depth);
      emit_str("\x5d\xc3", 2);  // pop ebp; ret
    } else if (strcmp(tok, "if") == 0) {
      char *cond = get_token();
      assert(strcmp(cond, "}") != 0);
      push_expr(cond, 0);
      int else_lab = gen_label();
      pop_var(1);
      emit_str("\x58\x83\xF8\x00\x0F\x84", 6);  // pop eax; cmp eax, 0; je rel
      emit32(compute_rel(get_symbol(write_label(else_lab), 0)));
      parse_block();
      char *else_tok = get_token();
      if (strcmp(else_tok, "else") == 0) {
        int fi_lab = gen_label();
        emit(0xe9);  // jmp rel
        emit32(compute_rel(get_symbol(write_label(fi_lab), 0)));
        add_symbol(write_label(else_lab), current_loc, -1);
        parse_block();
        add_symbol(write_label(fi_lab), current_loc, -1);
      } else {
        add_symbol(write_label(else_lab), current_loc, -1);
        give_back_token();
      }
    } else if (strcmp(tok, "while") == 0) {
      char *cond = get_token();
      assert(strcmp(cond, "}") != 0);
      int restart_lab = gen_label();
      int end_lab = gen_label();
      add_symbol(write_label(restart_lab), current_loc, -1);
      push_expr(cond, 0);
      pop_var(1);
      emit_str("\x58\x83\xF8\x00\x0F\x84", 6);  // pop eax; cmp eax, 0; je rel
      emit32(compute_rel(get_symbol(write_label(end_lab), 0)));
      parse_block();
      emit(0xe9);  // jmp rel
      emit32(compute_rel(get_symbol(write_label(restart_lab), 0)));
      add_symbol(write_label(end_lab), current_loc, -1);
    } else if (*tok == '$') {
      char *name = tok + 1;
      assert(*name != '\0');
      push_var(name, 0);
      emit_str("\x83\xec\x04", 3);  // sub esp, 4
    } else if (*tok == '"') {
      int str_lab = gen_label();
      int jmp_lab = gen_label();
      emit(0xe9);  // jmp rel
      emit32(compute_rel(get_symbol(write_label(jmp_lab), 0)));
      add_symbol(write_label(str_lab), current_loc, -1);
      emit_escaped_string(tok);
      add_symbol(write_label(jmp_lab), current_loc, -1);
      push_var(TEMP_VAR, 1);
      emit(0x68);  // push val
      emit32(get_symbol(write_label(str_lab), 0));
    } else {
      // Check if we want the address
      int want_addr = 0;
      if (*tok == '&') {
        tok++;
        want_addr = 1;
      }
      push_expr(tok, want_addr);
    }
  }
  emit_str("\x81\xc4", 2);  // add esp, ..
  assert(stack_depth >= saved_stack_depth);
  emit32(4 * (stack_depth - saved_stack_depth));
  stack_depth = saved_stack_depth;
  block_depth--;
}

int decode_number_or_symbol(char *str) {
  int val;
  int res = decode_number(str, &val);
  if (res) {
    return val;
  }
  int arity;
  return get_symbol(str, &arity);
}

void parse() {
  while (1) {
    char *tok = get_token();
    if (*tok == 0) {
      break;
    }
    if (strcmp(tok, "fun") == 0) {
      char *name = get_token();
      strcpy(buf2, token_buf);
      name = buf2;
      char *arity_str = get_token();
      int arity = atoi(arity_str);
      add_symbol(name, current_loc, arity);
      emit_str("\x55\x89\xe5", 3);  // push ebp; mov ebp, esp
      parse_block();
      emit_str("\x5d\xc3", 2);  // pop ebp; ret
    } else if (strcmp(tok, "const") == 0) {
      char *name = get_token();
      strcpy(buf2, token_buf);
      name = buf2;
      char *val_str = get_token();
      int val = decode_number_or_symbol(val_str);
      add_symbol(name, val, -2);
    } else if (*tok == '$') {
      char *name = tok + 1;
      assert(*name != '\0');
      add_symbol(name, current_loc, -1);
      emit32(0);
    } else if (*tok == '%') {
      char *name = tok + 1;
      add_symbol(name, current_loc, -1);
      char *len_str = get_token();
      int len = decode_number_or_symbol(len_str);
      while (len > 0) {
        emit(0);
        len--;
      }
    } else {
      assert(0);
    }
  }
}

void emit_preamble() {
  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  8b 4c 24 08             mov    ecx,DWORD PTR [esp+0x8]
    8:  89 01                   mov    DWORD PTR [ecx],eax
    a:  c3                      ret
  */
  add_symbol("=", current_loc, 2);
  emit_str("\x8B\x44\x24\x04\x8B\x4C\x24\x08\x89\x01\xC3", 11);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  8b 44 85 08             mov    eax,DWORD PTR [ebp+eax*4+0x8]
    8:  c3                      ret
   */
  add_symbol("param", current_loc, 1);
  emit_str("\x8B\x44\x24\x04\x8B\x44\x85\x08\xC3", 9);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  03 44 24 08             add    eax,DWORD PTR [esp+0x8]
    8:  c3                      ret
  */
  add_symbol("+", current_loc, 2);
  emit_str("\x8B\x44\x24\x04\x03\x44\x24\x08\xC3", 9);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  2b 44 24 08             sub    eax,DWORD PTR [esp+0x8]
    8:  c3                      ret
  */
  add_symbol("-", current_loc, 2);
  emit_str("\x8B\x44\x24\x04\x2b\x44\x24\x08\xC3", 9);
}

int main() {
  read_fd = platform_open_file("test.g");
  block_depth = 0;
  stack_depth = 0;
  symbol_num = 0;

  for (stage = 0; stage < 2; stage++) {
    platform_reset_file(read_fd);
    label_num = 0;
    current_loc = 0x100000;
    emit_preamble();
    parse();
    assert(block_depth == 0);
    assert(stack_depth == 0);
  }

  return 0;
}