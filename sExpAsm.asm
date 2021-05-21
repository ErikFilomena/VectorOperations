

.data
	nr  REAL4 	0.5, 0.166666667, 0.041666667, 0.008333333, 0.001388889, 0.000198413, 2.48016E-05, 2.75573E-06	
	nrr real4	2.75573E-07, 2.50521E-08, 2.08768E-09, 1.6059E-10, 1.14707E-11,	7.64716E-13

.code
;xmm0 contains x
sExpAsm PROC
	lea r10, nr
	movss xmm0, dword ptr [r10]
	movss xmm0, dword ptr [r10+4]
	movss xmm0, dword ptr [r10+8]
	movss xmm0, dword ptr [r10+12]
	movss xmm0, dword ptr [r10+16]
	movss xmm0, dword ptr [r10+20]
	movss xmm0, dword ptr [r10+24]
	movss xmm0, dword ptr [r10+28]
	movss xmm0, dword ptr [r10+32]
	movss xmm0, dword ptr [r10+36]
	movss xmm0, dword ptr [r10+40]
	movss xmm0, dword ptr [r10+44]
	movss xmm0, dword ptr [r10+48]
	movss xmm0, dword ptr [r10+52]
	movss xmm0, dword ptr [r10+56]
	movss xmm0, dword ptr [r10+60]
	ret
sExpAsm ENDP

END