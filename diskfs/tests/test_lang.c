/* This file is part of asmc, a bootstrapping OS with minimal seed
   Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
   https://gitlab.com/giomasce/asmc

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>. */

// Test from http://www.unixwiz.net/techtips/reading-cdecl.html
typedef char *(*(**foo [][2*3+1])())[];

int;

struct OtherStruct {
  int x, y, z;
};

int init1 = 10 + 20;
struct OtherStruct init2 = { 1000, 2 * 5, 200 / 120};

typedef struct Test {
  int x:5, y:6;
  struct OtherStruct s;
  char z:0;
  struct Test *ptr;
} Test2, *TestPtr, **TestPtrPtr;

typedef union Test {
  int x, y;
  struct OtherStruct s;
  char z;
  struct Test *ptr;
} Test3;

enum Enum {
  ZERO,
  ONE,
  TWO,
  TEN = 5+3+2,
  ELEVEN
};

int test_false() {
  return 0;
}

int test_true() {
  return 1;
}

int do_sum(int x, char y) {
  return x+y;
}

int test_while() {
  int i;
  int sum;
  i = 0;
  sum = 0;
  while (i < 200) {
    i = i + 1;
    if (i == 10) continue;
    sum = do_sum(sum, i);
    if (i == 100) break;
  }
  return sum;
}

int test_for() {
  int i;
  int sum;
  sum = 0;
  for (i = 0; i < 200; i = i + 1) {
    if (i == 10) continue;
    sum = do_sum(sum, i);
    if (i == 100) break;
  }
  return sum;
}

int test_array() {
  short x[3];
  *(x+1) = *x = 200;
  *x = 100;
  //*(x+1) = 200;
  *(x+2) = 300;
  //return (x+2)-x;
  return *(1+x);
}

int test_struct() {
  Test2 t;
  t.x = 10;
  t.y = 20;
  t.s.x = 30;
  t.s.y = 40;
  t.s.z = 50;
  Test2 t2;
  t2 = t;
  Test2 *ptr;
  ptr = &t2;
  return ptr->s.y;
}

extern int glob2;

// C++ comment
int glob; /* C comment */
int glob2;   \
Test2 glob3;
Test3 glob4;

int test_enum() {
  return ELEVEN;
}

char *global_str = "global test string\n";

int test_strings() {
  if (*global_str != 'g') return 0;
  if (*"local test string\n" != 'l') return 0;
  return 1;
}

#define YES
#undef NO

int test_define() {
  int i = 0;
#ifdef NO
  return 0;
#ifdef YES
  return 0;
#endif
#endif
  i = i + 1;
#ifdef NO
  return 0;
#else
  i = i + 1;
#ifndef NO
  i = i + 1;
#else
  return 0;
#endif
#endif
#ifdef YES
  i = i + 1;
#else
 return 0;
#endif
 return i;
}

#undef YES
#undef NO

int test_extension() {
  char c = 0-1;
  return c;
}