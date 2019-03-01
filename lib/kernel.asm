;; This file is part of asmc, a bootstrapping OS with minimal seed
;; Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

  STACK_SIZE equ 65536
  ;; STACK_SIZE equ 8388608

  MAX_OPEN_FILE_NUM equ 1024
  FILE_RECORD_SIZE equ 16
  FILE_RECORD_SIZE_LOG equ 4

heap_ptr:
  resd 1

open_files:
  resd 1

open_file_num:
  resd 1

write_mem_ptr:
  resd 1

str_exit:
  db 'The execution has finished, bye bye...'
  db NEWLINE
  db 0
str_panic:
  db 'PANIC!'
  db NEWLINE
  db 0

str_hello_asmc:
  db 'Hello, asmc!'
  db NEWLINE
  db 0

str_init_heap_stack:
  db 'Initializing heap and stack... '
  db 0
str_init_files:
  db 'Initializing files table... '
  db 0
str_init_asm_symbols_table:
  db 'Initializing symbols table... '
  db 0
str_done:
  db 'done!'
  db NEWLINE
  db 0

str_empty:
  db 0

entry:
  ;; Make it double sure that we do not have interrupts around
  cli

  ;; Use the multiboot header as temporary stack
  mov esp, temp_stack_top
  and esp, 0xfffffff0

  ;; Find the end of the ar initrd
  mov ecx, str_empty
  call walk_initrd

  ;; Initialize the stack and the heap, aligning to 16 bytes
  sub edx, 1
  or edx, 0xf
  add edx, 1
  add edx, STACK_SIZE
  mov esp, edx
  mov [heap_ptr], edx

  ;; Initialize stdout
  call stdout_setup

  ;; Log
  push str_hello_asmc
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_init_heap_stack
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_done
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_init_files
  push 1
  call platform_log
  add esp, 8

  ;; Initialize file table
  mov DWORD [open_file_num], 0
  mov eax, FILE_RECORD_SIZE * MAX_OPEN_FILE_NUM
  call allocate
  mov [open_files], eax

  ;; Log
  push str_done
  push 1
  call platform_log
  add esp, 8

  ;; Log
  push str_init_asm_symbols_table
  push 1
  call platform_log
  add esp, 8

  ;; Init symbol table
  call init_symbols

  ;; Expose some kernel symbols
  call init_kernel_api

  ;; Log
  push str_done
  push 1
  call platform_log
  add esp, 8

  ;; Call start
  call start

  call platform_exit

platform_exit:
  ;; Write an exit string
  push str_exit
  push 1
  call platform_log
  add esp, 8

  mov eax, 0
  jmp loop_forever


platform_panic:
  ;; Write an exit string
  push str_panic
  push 1
  call platform_log
  add esp, 8

  mov eax, 1
  jmp loop_forever


platform_write_char:
  ;; Switch depending on the requested file descriptor
  mov eax, [esp+4]
  cmp eax, 0
  je platform_write_char_mem
  cmp eax, 1
  je platform_write_char_stdout
  cmp eax, 2
  je platform_write_char_stdout
  ret

platform_write_char_mem:
  ;; Write to memory and update pointer
  mov eax, [esp+8]
  mov ecx, write_mem_ptr
  mov edx, [ecx]
  mov [edx], al
  add edx, 1
  mov [ecx], edx

  ;; Log (for debug)
  ;; push edx
  ;; call debug_log_itoa
  ;; add esp, 4
  ;; push str_newline
  ;; call debug_log
  ;; add esp, 4

  ret


platform_log:
  ;; Use ebx for the fd and esi for the string
  mov eax, [esp+4]
  mov edx, [esp+8]
  push ebx
  push esi
  mov ebx, eax
  mov esi, edx

  ;; Loop over the string and call platform_write_char
platform_log_loop:
  mov ecx, 0
  mov cl, [esi]
  cmp cl, 0
  je platform_log_loop_ret
  push ecx
  push ebx
  call platform_write_char
  add esp, 8
  add esi, 1
  jmp platform_log_loop

platform_log_loop_ret:
  pop esi
  pop ebx
  ret


platform_allocate:
  mov eax, [esp+4]

  ;; Size in EAX
  ;; Destroys: ECX
  ;; Returns: EAX
allocate:
  dec eax
  or eax, 0x3
  inc eax
  mov ecx, eax
  mov eax, [heap_ptr]
  add ecx, eax
  mov [heap_ptr], ecx
  ret


platform_open_file:
  push ebp
  mov ebp, esp
  push esi
  push edi

  ;; Find the file pointers
  mov ecx, [ebp+8]
  call walk_initrd

  ;; Find the new file record (stored in eax)
  mov ecx, [open_file_num]
  shl ecx, FILE_RECORD_SIZE_LOG
  add ecx, [open_files]

  ;; Set file pointers in the file record
  mov [ecx], eax
  mov [ecx+4], eax
  mov [ecx+8], edx

  ;; Return and increment the open file number
  mov eax, [open_file_num]
  add DWORD [open_file_num], 1

  pop edi
  pop esi
  pop ebp

  ret


platform_reset_file:
  ;; Find the file record
  mov eax, [esp+4]
  shl eax, FILE_RECORD_SIZE_LOG
  add eax, [open_files]

  ;; Reset it to the beginning
  mov ecx, [eax]
  mov [eax+4], ecx

  ret


platform_read_char:
  ;; Find the file record
  mov eax, [esp+4]
  shl eax, FILE_RECORD_SIZE_LOG
  add eax, [open_files]

  ;; Check if we are at the end
  mov ecx, [eax+4]
  cmp ecx, [eax+8]
  je platform_read_char_eof

  ;; Return a character and increment pointer
  mov edx, 0
  mov dl, [ecx]
  add DWORD [eax+4], 1
  mov eax, edx
  ret

platform_read_char_eof:
  ;; Return -1
  mov eax, 0xffffffff
  ret


str_platform_panic:
  db 'platform_panic'
  db 0
str_platform_exit:
  db 'platform_exit'
  db 0
str_platform_open_file:
  db 'platform_open_file'
  db 0
str_platform_read_char:
  db 'platform_read_char'
  db 0
str_platform_write_char:
  db 'platform_write_char'
  db 0
str_platform_reset_file:
  db 'platform_reset_file'
  db 0
str_platform_log:
  db 'platform_log'
  db 0
str_platform_allocate:
  db 'platform_allocate'
  db 0
str_platform_get_symbol:
  db 'platform_get_symbol'
  db 0

  ;; Initialize the symbols table with the "kernel API"
init_kernel_api:
  push 0
  push platform_panic
  push str_platform_panic
  call add_symbol
  add esp, 12

  push 0
  push platform_exit
  push str_platform_exit
  call add_symbol
  add esp, 12

  push 1
  push platform_open_file
  push str_platform_open_file
  call add_symbol
  add esp, 12

  push 1
  push platform_read_char
  push str_platform_read_char
  call add_symbol
  add esp, 12

  push 2
  push platform_write_char
  push str_platform_write_char
  call add_symbol
  add esp, 12

  push 1
  push platform_reset_file
  push str_platform_reset_file
  call add_symbol
  add esp, 12

  push 2
  push platform_log
  push str_platform_log
  call add_symbol
  add esp, 12

  push 1
  push platform_allocate
  push str_platform_allocate
  call add_symbol
  add esp, 12

  push 2
  push platform_get_symbol
  push str_platform_get_symbol
  call add_symbol
  add esp, 12

  ret


  ;; int platform_get_symbol(char *name, int *arity)
  ;; similar as find_symbol, but panic if it does not exist; retuns
  ;; the location and put the arity in *arity if arity is not null
platform_get_symbol:
  ;; Call find_symbol
  mov eax, [esp+4]
  mov ecx, [esp+8]
  push 0
  mov edx, esp
  push ecx
  push edx
  push eax
  call find_symbol
  add esp, 12

  ;; Panic if it does not exist
  cmp eax, 0
  je platform_panic

  ;; Return the symbol location
  pop eax

  ret
