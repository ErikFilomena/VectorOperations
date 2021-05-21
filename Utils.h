#pragma once

#include<time.h>
#include <stdio.h>


extern "C" size_t _stdcall LCGAsm(unsigned long long int x, unsigned int a, unsigned int c, unsigned int m);

double timeCounter;


void time_start() {
	timeCounter = clock();
}

void time_stop(const char* s) {
	timeCounter = clock() - timeCounter;
	printf("%s%f\n", s, timeCounter / CLOCKS_PER_SEC);
}