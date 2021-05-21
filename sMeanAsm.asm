
; rcx contains *x rdx contails len, r8 contains *sum(x), xmm0 contains(sum(x^2))
.code

sMeanAsm PROC
	;ymm0 stores sum(x^2) ymm1 stores sum(x)
	xorps xmm0,xmm0
	xorps xmm1,xmm1
L0:
	vmovups ymm2, ymmword ptr [rcx]
	vmulps ymm3, ymm2,ymm2
	vhaddps ymm3,ymm3,ymm3
	vhaddps ymm2,ymm2,ymm2
	vperm2f128 ymm4,ymm3,ymm3,1
	vperm2f128 ymm5,ymm2,ymm2,1

	vaddps ymm3,ymm3,ymm4
	vaddps ymm2,ymm2,ymm5

	haddps xmm3,xmm3
	haddps xmm2,xmm2
	addss xmm0,xmm3
	addss xmm1,xmm2

	add rcx,32
	sub rdx, 8
	test rdx,rdx
	jnz L0
	movss dword ptr[r8], xmm1
	ret
sMeanAsm ENDP

END