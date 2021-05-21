#include "Vector32.h"
#include "Defines.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#pragma once


vecf32::vecf32()
{

}

vecf32::vecf32(vecf32& src)
{
	size = src.size;
	align = src.align;
	data = (float*) malloc(align*sizeof(float));
	memcpy(data, src.data, align * sizeof(float));

}

vecf32::vecf32(size_t size):
	size(size)
{
	align = size + (size % 16 != 0) * (16 - size % 16);
	data = (float*)calloc(align, sizeof(float));
}

vecf32 vecf32::operator=(vecf32& src)
{
	if (this == &src) return *this;
	if (deletes) {
		if (data) free(data);
	}
	size = src.size;
	align = src.align;
	data = (float*)malloc(src.align*sizeof(float));
	memcpy(data, src.data, align * sizeof(float));
	deletes = true;
	return *this;
}

vecf32::~vecf32()
{
	if (deletes) {
		if (data)free(data);
	}
}

float &vecf32::operator()(size_t i)
{
#ifdef NDEBUG
	return data[i];
#else
	try {
		if (i < align) return data[i];
		throw 0;
	}
	catch (...) {fprintf(stderr, "Index out of bounds"); }
#endif	
}

void vecf32::Print(FILE* f)
{
	static char buffer[64];
	for (size_t i = 0; i < size; i++) {
		sprintf(buffer, "%f ", (*this)(i));
		fprintf(f, buffer);
	}
}

float Dot(vecf32& x, vecf32& y)
{
	return sDotAsmAvx(x.data,y.data,x.size);
}

void Had(vecf32& x, vecf32& y, vecf32& dst)
{
	if (dst.data) {
		if (dst.align == x.align) {
			sHadAsm(x.data, y.data, dst.data, x.size);
		}
		else {
			if (dst.deletes) {
				delete[] dst.data;
				dst.size = x.size;
				dst.align = x.align;
				dst.data = (float*)malloc(sizeof(float)*dst.align);
				dst.deletes = true;
				sHadAsm(x.data, y.data, dst.data, x.align);
			}
		}
	}
	else {
		dst.size = x.size;
		dst.align = x.align;
		dst.data = (float*)malloc(sizeof(float) * dst.align);
		dst.deletes = true;
		sHadAsm(x.data, y.data, dst.data, x.align);
	}
}

void Add(vecf32& x, vecf32& y, vecf32& dst, float alpha, float beta)
{
	bool isalpha = (alpha != 0);
	bool isbeta = (beta != 0);
	switch (isalpha)
	{
	case 0:
		if (isbeta) {
			sAddBetaAsm(x.data, y.data, dst.data, beta, x.align);
		}
		else {
			sAddAsm(x.data, y.data, dst.data, x.align);
		}
		break;
	case 1:
		switch (isbeta)
		{
		case 0:
			sAddAlphaAsm(x.data, y.data, dst.data, alpha, x.align);
			break;
		case 1:
			sAddAlphaBetaAsm(x.data, y.data, dst.data, alpha, x.align,beta);
			break;
		}
		break;
	}
}

void Sub(vecf32& x, vecf32& y, vecf32& dst, float alpha, float beta)
{	
	bool isalpha = (alpha != 0);
	bool isbeta = (beta != 0);
	switch (isalpha)
	{
	case 0:
		if (isbeta) {
			sAddBetaAsm(x.data, y.data, dst.data, -beta, x.align);
		}
		break;
	case 1:
		break;
	}
	if (alpha == 0 && beta == 0) {
		sSubAsm(x.data, y.data, dst.data, x.align);
	}
}
