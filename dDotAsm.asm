public dDotAsmAvx



.code
;rcx contains *x rdx contains *y r8 conains len
dDotAsmAvx PROC
	push r10
	vpxor xmm0, xmm0,xmm0
	mov r9, rdx
	xor rdx, rdx
	mov rax, r8
	mov r10, 4
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0:
	movsd xmm1, qword ptr [r9+rax]
	mulsd xmm1, qword ptr [rcx+rax]
	addsd xmm0, xmm1
	add rax, 8
	dec r8
	dec rdx
	test rdx, rdx
	jnz L0
L1:
	vmovupd ymm1, ymmword ptr [rcx + rax]
	vmovupd ymm2, ymmword ptr [r9 + rax]
	vmulpd ymm1,ymm1,ymm2
	vhaddpd ymm1, ymm1, ymm1
	vextractf128 xmm2,ymm1,1
	addsd xmm1,xmm2
	addsd xmm0,xmm1
	add rax, 32
	sub r8, 4
	test r8, r8
	jnz L1
	pop r10
	ret
dDotAsmAvx ENDP

END
