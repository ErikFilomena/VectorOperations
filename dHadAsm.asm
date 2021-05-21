.code

;rcx contains *x, rdx constains *y, r8 contains *dst r9 contains len
dHadAsm PROC
	
L1:	
	vmovupd ymm0, ymmword ptr [rcx]
	vmovupd ymm1, ymmword ptr [rcx+32]
	vmulpd	ymm0,ymm0,ymmword ptr [rdx]
	vmulpd	ymm1,ymm1,ymmword ptr [rdx+32]
	vmovupd ymmword ptr [r8], ymm0
	vmovupd ymmword ptr [r8+32], ymm1
	add rcx, 64
	add rdx, 64
	add r8, 64
	sub r9, 8
	test r9,r9
	jnz L1
	ret
dHadAsm ENDP

END