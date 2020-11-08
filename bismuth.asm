section .data
; This is stack of 4KB:
    db 4096 dup 0
stackbottom:
; Place to copy msg content into:
msg:
    db 1024 dup 0
; And finally our program:
program:
    dd  bismuthint ; We want to use our main interpreter, bismuth.
    dd      top, local, data
    dd          dataint
    dd              0x0a20202e
    dd              0x2e2e6948
    dd          endint, quote, eval, eval,
    dd      end, eval, top, getlocal, sub, quote, msg, copywords
    dd      top, local, msg, msg, top, getlocal, sub, output
    dd  endint


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

; Top of the stack is in edi, push dword onto it:
%macro bispush 1
    sub edi, 4
    mov dword [edi], %1
%endmacro

; Calling conventions for interpreters:
%macro biscall 1
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
    biscall eax             ; and start interpretation.
    ; After execution of program we will exit properly:
    mov ebx, 0              ; We have no error (error code = 0)
    mov eax, 1              ; and we want to exit.
    int 0x80                ; Send this to kernel.
    ; That's all! =)

bismuthint:
    dd bismuthint
    mov esi, [ebp+4]
bismuthloop:
    bisnext eax
    biscall eax
    jmp bismuthloop

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
    pop eax
    pop ebp
    pop esi
    bispop ebx
    push esi
    mov esi, ebx
    bisnext ebx
    add ebx, 4
    push ebp
    mov ebp, esp
    push eax
    jmp ebx

data:
    dd data
    mov esi, [ebp+4]
dataloop:
    bisnext eax
    cmp eax, eval
    je dataeval
    bispush eax
    jmp dataloop
dataeval:
    biscall eax
    jmp dataloop

dataint:
    dd dataint
dataintloop:
    bisnext eax
    cmp eax, eval
    je datainteval
    bispush eax
    jmp dataintloop
datainteval:
    biscall eax
    jmp dataloop

end:
    dd end
    mov esp, ebp
    pop ebp
    pop esi
    mov esp, ebp
    sub esp, 4
    mov [ebp+4], esi
    ret

endint:
    dd endint
    mov esp, ebp
    pop ebp
    pop esi
    mov esp, ebp
    sub esp, 4
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

top:
    dd top
    mov eax, stackbottom
    sub eax, edi
    bispush eax
    ret

local:
    dd local
    pop eax
    pop ebp
    pop esi
    bispop ebx
    push ebx
    push esi
    push ebp
    mov ebp, esp
    push eax
    ret

getlocal:
    dd getlocal
    pop eax
    pop ebp
    pop esi
    pop ebx
    bispush ebx
    push esi
    push ebp
    mov ebp, esp
    push eax
    ret

sub:
    dd sub
    bispop ebx
    bispop eax
    sub eax, ebx
    bispush eax
    ret
