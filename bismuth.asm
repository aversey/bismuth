section .data
; This is stack of 4KB:
    db 4096 dup 0
stackbottom:
; Place to copy msg content into:
msg:
    db 1024 dup 0
; And finally our program:
program:
    dd  bismuth ; We want to use our main interpreter, bismuth.
    dd      data
    dd          prog
    dd              data
    dd                  0x0a20202e
    dd                  0x2e2e6948
    dd              quote, eval, 0, pop
    dd          quote, eval, 0
    dd      0, quote, msg, copywords
    dd      data, msg, eval, msg, eval, 0, output
    dd  0


; The input is in esi, pop dword from it:
%macro bisnext 1
    mov %1, dword [esi]
    add esi, 4
%endmacro

; Top of the stack is in edi, pop dword from it:
%macro bispop 1
    mov %1, dword [edi]
    add edi, 4
%endmacro

; Top of the stack is in edi, pop byte from it:
%macro bispopbyte 1
    mov %1, byte [edi]
    inc edi
%endmacro

; Top of the stack is in edi, push dword onto it:
%macro bispush 1
    sub edi, 4
    mov dword [edi], %1
%endmacro

; Top of the stack is in edi, push byte onto it:
%macro bispushbyte 1
    dec edi
    mov byte [edi], %1
%endmacro

; Calling conventions for interpreters:
%macro bisinterpret 1
    push esi
    mov esi, %1
    bisnext eax
    add eax, 4
    push ebp
    mov ebp, esp
    call eax
    mov esp, ebp
    pop ebp
    pop esi
%endmacro


section .text
global _start
_start:
    mov esi, program        ; We will read and execute program
    mov edi, stackbottom    ; and write results onto stack.
    bisnext eax             ; Read interpreter
    bisinterpret eax        ; and start interpretation.
    ; After execution of program we will exit properly:
    mov ebx, 0              ; We have no error (error code = 0)
    mov eax, 1              ; and we want to exit.
    int 0x80                ; Send this to kernel.
    ; That's all! =)

bismuth:
    dd bismuth
    mov esi, [ebp+4]
bismuthloop:
    bisnext eax
    cmp eax, 0
    je bismuthend
    bisinterpret eax
    jmp bismuthloop
bismuthend:
    mov [ebp+4], esi
    ret

prog:
    dd prog
progloop:
    bisnext eax
    cmp eax, 0
    je progend
    bisinterpret eax
    jmp progloop
progend:
    ret

pop:
    dd pop
    add edi, 4
    ret

copy:
    dd copy
    mov eax, dword [edi]
    sub edi, 4
    mov dword [edi], eax
    ret

quote:
    dd quote
    mov esi, [ebp+4]
    bisnext eax
    bispush eax
    mov [ebp+4], esi
    ret

eval:
    dd eval
    mov esi, [ebp+4]
    bispop eax
    bisinterpret eax
    mov [ebp+4], esi
    ret

data:
    dd data
    mov esi, [ebp+4]
    push edi
dataloop:
    bisnext eax
    cmp eax, eval
    je dataeval
    cmp eax, 0
    je dataend
    bispush eax
    jmp dataloop
dataeval:
    bisinterpret eax
    jmp dataloop
dataend:
    pop eax
    sub eax, edi
    bispush eax
    mov [ebp+4], esi
    ret

copywords:
    dd copywords
    bispop ebx
    bispop ecx
    sub ebx, 4
copywordsloop:
    bispop eax
    mov dword [ebx+ecx], eax
    sub ecx, 4
    jnz copywordsloop
    ret

output:
    dd output
    bispop edx
    mov ecx, edi
    mov ebx, 1
    mov eax, 4
    int 0x80
    add edi, edx
    ret
