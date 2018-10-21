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

#include <stdio.h>

int test_fputs() {
  int ret;
  ret = fputs("This is a test string\n", stdout);
  return ret >= 0;
}

int test_puts() {
  int ret;
  ret = puts("This is a test string\n");
  return ret >= 0;
}

int test_putchar() {
  int ret;
  ret = putchar('X');
  return ret == 'X';
}

int test_fputc() {
  int ret;
  ret = fputc('X', stdout);
  return ret == 'X';
}

int test_putc() {
  int ret;
  ret = putc('X', stdout);
  return ret == 'X';
}