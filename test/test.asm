;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
;; https://gitlab.com/giomasce/asmc

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

first:
  add eax, ebx                  ; Test line
  add eax, 0x2200
  add al, 0x22
second:
  add byte [eax+second+eax], 0x22
  add ebx, [eax+second+eax]
  add bh, [eax+second+eax]
  add dword [eax+second+eax], 0x22
  add al, second

  mul edx
  neg BYTE [edx]
  not dWoRd [edx+ebx*4+0x2244]

  jmp first
  call second
  jmp [eax]
  call [eax+ebx*2]

third:
  jz third
  je third
  ja third
  jna third
  jc third

  ret

  push eax
  push ebx
  push [eax+ebx*2+first]
  push first
  push 0xff5500
  pop eax
  pop ebx

  int 0x80

  sal al, 10
  shl DWORD [eax], 12
  sar BYTE [eax], cl
  shr cl, cl

  shld edx, eax, 2
  shld [edx], eax, cl
  shrd edx, eax, 2
  shrd [edx], eax, cl

  shl bx, 15
  inc bx

  movzx eax, byte [ebx]
  movsx eax, word [ebx]
  movzx eax, cx
  movsx eax, ch
  movzx	ax,byte [esi]

  inc ebx
  dec ah

  stc
  std
  sti
  cmc
  clc
  cld
  cli

here:
  rep stosb
  stosw
  stosd
  lodsb
  lodsw
  lodsd
there:

  rep stos byte [eax]
  stos word [ebx]
  stos dword [edi]
  lods byte [eax]
  rep lods word [ebx]
  lods dword [edi]

  xchg eax, ebx
  xchg ecx, [edx+'abc']

  seta byte [ebp+10101110b]

  setne byte [ebp+eax*4+100H]
  jecxz here
  jcxz here
  jmp here
  ;; jecxz first
  jmp first
  loope here

  xlat byte [edx]
  xlatb

  lea esi, [esi+ecx-10]
  mov ax, 20
  mov eax, there-here+4

  bt [eax+0x345], 3
  btc [0x345], 4
  btr eax, 5
  bts [ebx+ecx*8+0x1234], 6
  bt ax, 10

  mov eax, 1 + 1 shl 8
  mov eax, -1
  mov eax, not 1
  mov ebx, 'fas'+1Ah shl 24

  push eax ebx ecx

  imul ecx
  imul ecx, [edx]
  imul ebx, [edx], 0x10

  cbw
  cwde

  bsf eax, [edi]
  bsr eax, [edi]

  mov ecx, 0x10000000
  rdpmc

  dd there-here
  dw there-here,10,11,there-here
  dd 0x11223344
  rw 2

  db 'Hello world!',0xa,0,-1
