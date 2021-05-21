.code
;rcx contains *x rdx contains *y r8 conains len
sDotAsmAvx PROC
	push r10
	vpxor xmm0, xmm0,xmm0 ;Zeroes return register
	mov r9, rdx		; stores *y in r9
	xor rdx, rdx	; Zeroes rdx tro receive remainder of div
	mov rax, r8		; Stores len in rax
	mov r10, 16		; Stores 16 in r10
	div r10			; rax/r10
	xor rax, rax	;Zeroes rax
	test rdx, rdx	;Test if len is divisible by 16
	jz L1
	
L0:	;takes care of residuals
	movss xmm1, dword ptr [r9+rax]
	mulss xmm1, dword ptr [rcx+rax]
	addss xmm0, xmm1
	add rax, 4
	dec r8
	dec rdx
	test rdx, rdx
	jnz L0
L1:	; Checks if there is anything left to be done
	test r8, r8
	jz L3
	vxorps ymm3,ymm3,ymm3	;Cleans accumulators
	vxorps ymm4, ymm4,ymm4
L2:
	;load data into ymm i is stored in r8
	vmovups ymm1, ymmword ptr [rcx + rax]		;Loads x[i:i+8]
	vmovups ymm2, ymmword ptr [rcx+ rax + 32]	;Loads x[i+9:i+16]

	; multiply
	vmulps ymm1, ymm1,ymmword ptr [r9+ rax]		;multiplies x[i:i+8]*y[i:i+8]
	vmulps ymm2, ymm2,ymmword ptr [r9+ rax +32] ;multipliesx[i+9:i+16]*y[i+9:i+16]

	;store in accumulators
	vaddps ymm3,ymm3,ymm1						;Store in accumulator
	vaddps ymm4,ymm4,ymm2
	add rax, 64
	sub r8, 16
	test r8, r8
	jnz L2
	vaddps ymm3,ymm3,ymm4
	vhaddps	ymm3,ymm3,ymm3
	vperm2f128 ymm4, ymm3,ymm3,1
	addps xmm3,xmm4
	haddps xmm3,xmm3
	addss xmm0,xmm3
L3:
	pop r10	
	ret
sDotAsmAvx ENDP

;rcx contains *x, rdx constains *y, r8 contains *dst r9 contains len
sHadAsm PROC
	push r10
	push r11
	mov r11, rdx
	xor rdx, rdx
	mov r10, 16
	mov rax, r9
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0: 
	movss xmm0, dword ptr[rcx+rax]
	mulss xmm0, dword ptr[r11+rax]
	movss dword ptr[r8+rax], xmm0
	add rax, 4
	dec r9
	dec rdx
	test rdx, rdx
	jnz L0

L1:	test r9, r9 ;check if ended task
	jz L3
L2:
	vmovups ymm0, ymmword ptr [rcx + rax]
	vmovups ymm1, ymmword ptr [rcx + rax + 32]
	vmulps	ymm0,ymm0,ymmword ptr [r11+rax]
	vmulps	ymm1,ymm1,ymmword ptr [r11 +rax+32]
	vmovups ymmword ptr [r8+rax], ymm0
	vmovups ymmword ptr [r8+ rax +32], ymm1
	add rax, 64
	sub r9, 16
	test r9,r9
	jnz L2
L3:
	pop r11
	pop r10
	ret
sHadAsm ENDP

;rcx contains *x, rdx constains *y, r8 contains *dst r9 contains len
sAddAsm PROC
	mov r11, rdx
	xor rdx, rdx
	mov r10, 16
	mov rax, r9
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0: 
	movss xmm0, dword ptr[rcx+rax]
	addss xmm0, dword ptr[r11+rax]
	movss dword ptr[r8+rax], xmm0
	add rax, 4
	dec r9
	dec rdx
	test rdx, rdx
	jnz L0

L1:	test r9, r9 ;check if ended task
	jz L3
L2:
	vmovups ymm0, ymmword ptr [rcx + rax]
	vmovups ymm1, ymmword ptr [rcx + rax + 32]
	vaddps	ymm0,ymm0,ymmword ptr [r11+rax]
	vaddps	ymm1,ymm1,ymmword ptr [r11 +rax+32]
	vmovups ymmword ptr [r8+rax], ymm0
	vmovups ymmword ptr [r8+ rax +32], ymm1
	add rax, 64
	sub r9, 16
	test r9,r9
	jnz L2
L3:
	ret
sAddAsm ENDP


;rcx contains *x, rdx constains *y, r8 contains *dst xmm3 constains alpha stack contains len
sAddAlphaAsm PROC
	mov r9, qword ptr[rsp+28h]
	push rbp
	mov rbp, rsp
	sub rsp, 32
	movss dword ptr[rsp], xmm3
	movss dword ptr[rsp+4], xmm3
	movss dword ptr[rsp+8], xmm3
	movss dword ptr[rsp+12], xmm3
	movss dword ptr[rsp+16], xmm3
	movss dword ptr[rsp+20], xmm3
	movss dword ptr[rsp+24], xmm3
	movss dword ptr[rsp+28], xmm3
	vmovups ymm2,ymmword ptr [rsp]
	mov r11, rdx
	xor rdx, rdx
	mov r10, 16
	mov rax, r9
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0: 
	movss xmm0, dword ptr[r11+rax]
	mulss xmm0, xmm2
	addss xmm0, dword ptr[rcx+rax]
	movss dword ptr[r8+rax], xmm0
	add rax, 4
	dec r9
	dec rdx
	test rdx, rdx
	jnz L0

L1:	test r9, r9 ;check if ended task
	jz L3
L2:
	vmovups ymm0, ymmword ptr [r11+rax]
	vmovups ymm1, ymmword ptr [r11 +rax+32]
	vmulps ymm0,ymm0,ymm2
	vmulps ymm1,ymm1,ymm2
	vaddps	ymm0,ymm0,ymmword ptr [rcx + rax]
	vaddps	ymm1,ymm1,ymmword ptr [rcx + rax + 32]
	vmovups ymmword ptr [r8+rax], ymm0
	vmovups ymmword ptr [r8+ rax +32], ymm1
	add rax, 64
	sub r9, 16
	test r9,r9
	jnz L2
L3:
	mov rsp, rbp
	pop rbp
	ret
sAddAlphaAsm ENDP

;rcx contains *x, rdx constains *y, r8 contains *dst xmm3 constains beta stack contains len
;Use if alpha =1 and beta !=0
sAddBetaAsm PROC
mov r9, qword ptr[rsp+28h]
	push rbp
	mov rbp, rsp
	sub rsp, 32
	movss dword ptr[rsp], xmm3
	movss dword ptr[rsp+4], xmm3
	movss dword ptr[rsp+8], xmm3
	movss dword ptr[rsp+12], xmm3
	movss dword ptr[rsp+16], xmm3
	movss dword ptr[rsp+20], xmm3
	movss dword ptr[rsp+24], xmm3
	movss dword ptr[rsp+28], xmm3
	vmovups ymm2,ymmword ptr [rsp]
	mov r11, rdx
	xor rdx, rdx
	mov r10, 16
	mov rax, r9
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0: 
	movss xmm0, dword ptr[rcx+rax]
	mulss xmm0, xmm2
	addss xmm0, dword ptr[r11+rax]
	movss dword ptr[r8+rax], xmm0
	add rax, 4
	dec r9
	dec rdx
	test rdx, rdx
	jnz L0

L1:	test r9, r9 ;check if ended task
	jz L3
L2:
	vmovups ymm0, ymmword ptr [rcx + rax]
	vmovups ymm1, ymmword ptr [rcx + rax + 32]
	vmulps ymm0,ymm0,ymm2
	vmulps ymm1,ymm1,ymm2
	vaddps	ymm0,ymm0,ymmword ptr [r11+rax]
	vaddps	ymm1,ymm1,ymmword ptr [r11 +rax+32]
	vmovups ymmword ptr [r8+rax], ymm0
	vmovups ymmword ptr [r8+ rax +32], ymm1
	add rax, 64
	sub r9, 16
	test r9,r9
	jnz L2
L3:
	mov rsp, rbp
	pop rbp
	ret
sAddBetaAsm ENDP

;rcx contains *x, rdx constains *y, r8 contains *dst xmm3 constains alpha stack contains len and beta
sAddAlphaBetaAsm PROC
	mov r9, qword ptr[rsp+28h]
	push rbp
	mov rbp, rsp
	lea rsp, [rsp-20h]
	movss dword ptr[rsp], xmm3
	movss dword ptr[rsp+4], xmm3
	movss dword ptr[rsp+8], xmm3
	movss dword ptr[rsp+12], xmm3
	movss dword ptr[rsp+16], xmm3
	movss dword ptr[rsp+20], xmm3
	movss dword ptr[rsp+24], xmm3
	movss dword ptr[rsp+28], xmm3
	vmovups ymm2,ymmword ptr [rsp];contains alpha
	movss xmm3, dword ptr [rsp+58h]
	movss dword ptr[rsp], xmm3
	movss dword ptr[rsp+4], xmm3
	movss dword ptr[rsp+8], xmm3
	movss dword ptr[rsp+12], xmm3
	movss dword ptr[rsp+16], xmm3
	movss dword ptr[rsp+20], xmm3
	movss dword ptr[rsp+24], xmm3
	movss dword ptr[rsp+28], xmm3
	vmovups ymm4,ymmword ptr [rsp];contains beta
	mov r11, rdx
	xor rdx, rdx
	mov r10, 16
	mov rax, r9
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0: 
	movss xmm0, dword ptr[rcx+rax]
	movss xmm5, dword ptr[r11+rax]
	mulss xmm0, xmm2
	mulss xmm5, xmm4
	addss xmm0, xmm5
	movss dword ptr[r8+rax], xmm0
	add rax, 4
	dec r9
	dec rdx
	test rdx, rdx
	jnz L0

L1:	test r9, r9 ;check if ended task
	jz L3
L2:
	vmovups ymm0, ymmword ptr [rcx + rax]
	vmovups ymm1, ymmword ptr [rcx + rax + 32]
	vmovups ymm3, ymmword ptr [r11+rax]
	vmovups ymm6, ymmword ptr [r11 +rax+32]
	vmulps ymm0,ymm0,ymm4
	vmulps ymm1,ymm1,ymm4
	vmulps ymm3,ymm3,ymm2
	vmulps ymm6,ymm6,ymm2
	vaddps ymm0,ymm0,ymm3
	vaddps ymm1,ymm1,ymm6
	vmovups ymmword ptr [r8+rax], ymm0
	vmovups ymmword ptr [r8+ rax +32], ymm1
	add rax, 64
	sub r9, 16
	test r9,r9
	jnz L2
L3:
	mov rsp, rbp
	pop rbp
	ret
sAddAlphaBetaAsm ENDP


;rcx contains *x, rdx constains *y, r8 contains *dst r9 contains len
sSubAsm PROC
	mov r11, rdx
	xor rdx, rdx
	mov r10, 16
	mov rax, r9
	div r10
	xor rax, rax
	test rdx, rdx
	jz L1
L0: 
	movss xmm0, dword ptr[rcx+rax]
	subss xmm0, dword ptr[r11+rax]
	movss dword ptr[r8+rax], xmm0
	add rax, 4
	dec r9
	dec rdx
	test rdx, rdx
	jnz L0

L1:	test r9, r9 ;check if ended task
	jz L3
L2:
	vmovups ymm0, ymmword ptr [rcx + rax]
	vmovups ymm1, ymmword ptr [rcx + rax + 32]
	vsubps	ymm0,ymm0,ymmword ptr [r11+rax]
	vsubps	ymm1,ymm1,ymmword ptr [r11 +rax+32]
	vmovups ymmword ptr [r8+rax], ymm0
	vmovups ymmword ptr [r8+ rax +32], ymm1
	add rax, 64
	sub r9, 16
	test r9,r9
	jnz L2
L3:
	ret
sSubAsm ENDP



END

