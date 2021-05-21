#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <intrin.h>
#include <omp.h>
#include "Vector32.h"
enum Order{ROW,COL};

#define min(a,b) (a<b)?a:b

struct matf32 {

	size_t n;
	size_t m;
	Order order;
	size_t align;
	float* data=nullptr;

	inline matf32();
	inline matf32(matf32& src);
	inline matf32(size_t n, size_t m, Order order);

	inline matf32 operator=(matf32& src);
	inline float& operator()(size_t i, size_t j);
	inline float* operator()(size_t i);

	virtual ~matf32();

	void Print(FILE* f = stdout);
};


matf32 matf32::operator=(matf32& src)
{
	if (this == &src) return *this;
	if (data) {
		_aligned_free(data);
	}
	n = src.n;
	m = src.m;
	align = src.align;
	order = src.order;
	switch (order)
	{
	case ROW:
		data = data = (float*)_aligned_malloc(align * m * sizeof(float), 64);
		memcpy(data, src.data, align * m * sizeof(float));
		break;
	case COL:
		data = (float*)_aligned_malloc(64, align * n * sizeof(float));
		memcpy(data, src.data, align * n * sizeof(float));
		break;
	}
	return *this;
}

matf32::matf32(matf32& src) :
	n(src.n), m(src.m), order(src.order), align(src.align)
{
	switch (order)
	{
	case ROW:
		data = (float*)_aligned_malloc(align * m * sizeof(float), 64);
		memcpy(data, src.data, align * m * sizeof(float));
		break;
	case COL:
		data = (float*)_aligned_malloc(64, align * n * sizeof(float));
		memcpy(data, src.data, align * n * sizeof(float));
		break;
	}
}

matf32::matf32(size_t n, size_t m, Order order) :
	n(n), m(m), order(order)
{
	switch (order)
	{
	case ROW:
		align = m + (m % 16 != 0) * (16 - m % 16);
		data = (float*)_aligned_malloc(align * n * sizeof(float), 64);
		memset(data, 0, align * n * sizeof(float));
		break;
	case COL:
		align = n + (n % 16 != 0) * (16 - n % 16);
		data = (float*)_aligned_malloc(align * m * sizeof(float), 64);
		memset(data, 0, align * m * sizeof(float));
		break;
	}
}



float& matf32::operator()(size_t i, size_t j)
{
	switch (order)
	{
	case ROW:
		return data[i * align + j];
		break;
	case COL:
		return data[j * align + i];
		break;
	}
}

inline float* matf32::operator()(size_t i)
{
	return &data[i * align];
}


matf32::~matf32()
{
	if (data) {
		_aligned_free(data);
	}
}

void matf32::Print(FILE* f)
{
	static char buffer[64];
	for (size_t i = 0; i < n; i++) {
		for (size_t j = 0; j < m; j++) {
			sprintf(buffer, "%f ", (*this)(i, j));
			fprintf(f, buffer);
		}
		fprintf(f, "\n");
	}
}

extern "C" float  Mat32DotAsm(float* arow, float* bcol,size_t len);

void Mult(matf32& A, matf32& B, matf32& C)
{

	
	if (A.order == ROW && B.order == COL) {
		const size_t CACHE_SIZE =8;
		size_t nAblocks = A.n / CACHE_SIZE + A.n % CACHE_SIZE;
		size_t nBblocks = B.m / CACHE_SIZE + B.m % CACHE_SIZE;
		
		int blkA;
		size_t aa = A.align;
		size_t ba = B.align;
		float* pa = A.data;
		float* pb = B.data;
#pragma omp parallel
		{
			size_t bsize;
			size_t oa;
#pragma omp for
			for (blkA = 0; blkA < nAblocks; blkA++) {
				size_t maxi = min(CACHE_SIZE*(blkA + 1), A.n);
				bsize = 0;
				for (size_t blkB = 0; blkB < nBblocks; blkB++) {
					size_t maxj = min(bsize + CACHE_SIZE, B.m);
					for (size_t j = bsize; j < maxj; j++) {
						for (size_t i = blkA * CACHE_SIZE, oa = i * aa; i < maxi; i++) {
							C(i, j) = Mat32DotAsm(pa + oa, pb + j * ba , aa);
							oa += aa;
						}
						
					}
					bsize += CACHE_SIZE;
				}
			}
		}

		
	}
	

}

void Mult2(matf32& A, matf32& B, matf32& C)
{


	if (A.order == ROW && B.order == COL) {
		const size_t CACHE_SIZE = 16;
		size_t nARowBlocks = A.n / CACHE_SIZE + A.n % CACHE_SIZE;
		size_t nBlocks = A.m / CACHE_SIZE + A.m % CACHE_SIZE;
		size_t nBColBlocks = B.m / CACHE_SIZE + B.m % CACHE_SIZE;

#pragma omp parallel
		{
			int aRowBlk;
			__m256 ymm[CACHE_SIZE][CACHE_SIZE];
			for (int i = 0; i < CACHE_SIZE; i++) {
				for (int j = 0; j < CACHE_SIZE; j++) {
					ymm[i][j] = _mm256_setzero_ps();
				}
			}
#pragma omp for
			for (aRowBlk = 0; aRowBlk < nARowBlocks; aRowBlk++) {
				size_t aOffset = (aRowBlk * CACHE_SIZE) * A.align;
				size_t maxi = min(CACHE_SIZE * (aRowBlk + 1), A.n);
				for (size_t bColBlk = 0; bColBlk < nBColBlocks; bColBlk++) {
					size_t bOffset = (bColBlk * CACHE_SIZE) * B.align;
					size_t maxj = min(CACHE_SIZE * (bColBlk + 1) + CACHE_SIZE, B.m);
					
					for (size_t blk = 0; blk < nBlocks; blk++) {
						size_t aBlkOffset = aOffset + blk*(maxi%16);
						size_t bBlkOffset = bOffset + blk*(maxj % 16);
						for (size_t i = 0; i < (maxi%CACHE_SIZE + 1); i++) {
							float* pa = &A.data[aBlkOffset + i * A.align];
							for (size_t j = 0; j < (maxj % CACHE_SIZE +1); j++) {
								float* pb = &B.data[bBlkOffset + j * B.align];
								ymm[i][j] = _mm256_fmadd_ps(_mm256_load_ps(pa), _mm256_load_ps(pb), ymm[i][j]);
							}
						}
					}

					for (size_t i = 0; i < 16; i++) {
						for (size_t j = 0; j < 16; j++) {
							__m256 ymm0 = _mm256_hadd_ps(ymm[i % 16][j % 16], ymm[i % 16][j % 16]);
							__m256 ymm1 = _mm256_permute2f128_ps(ymm0, ymm0, 1);
							ymm0 = _mm256_add_ps(ymm0, ymm1);
							ymm0 = _mm256_hadd_ps(ymm0, ymm0);
							ymm0 = _mm256_hadd_ps(ymm0, ymm0);
							C(i, j) = ymm1.m256_f32[0];
							ymm[i%16][j%16] = _mm256_setzero_ps();
						}
					}
				}
			}
		}
		
	}

}


//size_t nBlockARow = A.n / 16 + A.n % 16;
//size_t nBlockACol = A.m / 16 + A.m % 16;
//size_t nBlockBRow = B.n / 16 + B.n % 16;
//size_t nBlockBCol = B.m / 16 + B.m % 16;
//switch (C.order)
//{
//case COL:
//	memset(C.data, 0, C.align * C.n * sizeof(float));
//	break;
//default:
//	memset(C.data, 0, C.align * C.m * sizeof(float));
//	break;
//}
//
//int blkARow;
//#pragma omp parallel for
//for (blkARow = 0; blkARow < nBlockARow; blkARow++) {
//	size_t maxARow = min(blkARow * 16 + 16, A.n);
//	size_t indARow = blkARow * 16;
//	for (size_t blkACol = 0; blkACol < nBlockACol; blkACol++) {
//		size_t maxACol = min(blkACol * 16 + 16, A.m);
//		size_t indACol = blkACol * 16;
//		for (size_t blkBCol = 0; blkBCol < nBlockBCol; blkBCol++) {
//			size_t maxBCol = min(blkBCol * 16 + 16, B.m);
//			size_t indBCol = blkBCol * 16;
//
//			for (size_t aRowPos = indARow; aRowPos < maxARow; aRowPos++) {
//				for (size_t aColPos = indACol; aColPos < maxACol; aColPos++) {
//					size_t offset = aRowPos * A.align;
//					size_t co = aRowPos * C.align;
//					size_t ba = B.align;
//					for (size_t bColPos = indBCol; bColPos < maxBCol; bColPos++) {
//						C.data[co + bColPos] += A.data[offset + aColPos] * B.data[bColPos * ba + aColPos];
//					}
//				}
//			}
//		}
//	}
//}