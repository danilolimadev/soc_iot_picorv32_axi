.section .text.start
.global _start
_start:
  la sp, _stack_top
  call main
1:
  j 1b
