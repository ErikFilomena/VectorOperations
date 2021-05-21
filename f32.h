#pragma once

#include <vector>
#include <math.h>

struct f32;


struct triple {
	float x;
	float y;
	float z;
};

struct ComputationalGraphf32 {


	std::vector<float> values;
	std::vector<triple> gradient;

}GlobalGraph;

void prod(f32& x, triple& grad);

struct f32 {

	float val;
	triple grad = { 0,0,0 };
	f32* p1 = nullptr;
	f32* p2 = nullptr;
	void (*f) (f32&, triple&) = nullptr;

	void Eval();
	void Eval(float x);
	void Grad();
	void Self();

};


inline void f32::Eval() {
	if (f)f(*this, grad);
}

inline void f32::Eval(float x) {
	val = x;
}

inline void f32::Grad()
{
	if (p1)p1->grad.x += grad.x * grad.y;
	if (p2)p2->grad.x += grad.x * grad.z;
}

inline void f32::Self()
{
	grad.x = 1;
}

f32& operator*(f32& x, f32& y) {
	f32 result = { 0,{0,0,0},&x,&y,prod };
	return result;
}


void prod(f32& x, triple& grad) {
	x.val = x.p1->val * x.p2->val;
	grad = { 0, x.p2->val, x.p1->val };
}

void exp(f32& x, triple& grad) {
	x.val = exp(x.p1->val);
	grad = { 0, x.val, 0 };
}

f32 exp(f32& x) {
	f32 result = { 0,{0,0,0},&x,nullptr,exp };
	return result;
}

