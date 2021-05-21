#pragma once

#include <stdio.h>

extern "C" float _stdcall sDotAsmAvx(float* x, float* y, size_t len);
extern "C" void _stdcall sHadAsm(float* x, float* y, float* dst, size_t len);
extern "C" void _stdcall sAddAsm(float* x, float* y, float* dst, size_t len);
extern "C" void _stdcall sAddAlphaAsm(float* x, float* y, float* dst,float alpha, size_t len);
extern "C" void _stdcall sAddBetaAsm(float* x, float* y, float* dst, float beta, size_t len);
extern "C" void _stdcall sAddAlphaBetaAsm(float* x, float* y, float* dst, float alpha, size_t len,float beta);
extern "C" void _stdcall sSubAsm(float* x, float* y, float* dst, size_t len);

struct vecf32 {
	size_t size=0;
	size_t align=0;
	float* data=nullptr;
	bool isEmpty=true;
	bool deletes = true;


	vecf32();
	vecf32(vecf32& src);
	vecf32(size_t size);

	vecf32 operator=(vecf32& src);

	virtual ~vecf32();

	float &operator()(size_t i);

	void Print(FILE* f = stdout);
};

float Dot(vecf32& x, vecf32& y);
void Had(vecf32& x, vecf32& y, vecf32& dst);
void Add(vecf32& x, vecf32& y, vecf32& dst, float alpha = 0, float beta=0);
void Sub(vecf32& x, vecf32& y, vecf32& dst, float alpha = 0, float beta =0);