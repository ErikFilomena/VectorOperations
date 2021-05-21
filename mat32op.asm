.code

;rcx: *x rdx: *y, r8: len
Mat32DotAsm PROC
	vpxor ymm0,ymm0,ymm0; buffer1
	vpxor ymm8,ymm8,ymm8; buffer2
	xor rax,rax
L0:
	vmovaps ymm2,ymmword ptr [rcx + rax]
	vmovaps ymm3,ymmword ptr [rdx + rax]
	vfmadd231ps ymm0, ymm2,ymm3
	vmovaps ymm9,ymmword ptr [rcx + rax+32]
	vmovaps ymm10,ymmword ptr [rdx + rax+32]
	vfmadd231ps ymm8,ymm9,ymm10
	lea rax, [rax+64]
	sub r8, 16
	test r8,r8
	jnz L0
	vaddps ymm0,ymm0,ymm8
	vperm2f128	ymm1,ymm0,ymm0,1
	addps xmm0,xmm1
	haddps xmm0,xmm0
	haddps xmm0,xmm0
	ret
Mat32DotAsm ENDP








.data 
	
	extern WriteFile: PROC
	extern GetStdHandle:PROC
	msg BYTE "Hello world",10,0h
	byteswriten QWORD ?

.code

Hello PROC
	push rbp
	mov rbp, rsp
	mov ecx, -11
	sub rsp, 20h
	call GetStdHandle
	mov rcx, rax
	lea rdx, [msg]
	mov r8, LENGTHOF msg
	lea r9, [byteswriten]
	sub rsp, 8
	mov qword ptr[rsp],0
	sub rsp, 20h
	call WriteFile
	mov rsp, rbp
	pop rbp
	ret
Hello ENDP


END