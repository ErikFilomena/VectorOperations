#include "VectorClass.h"
#include <stdlib.h>
#include <string.h>

template<class NBR>
BaseVector<NBR>::~BaseVector()
{
	if (data) {
		if (selfInit) {
			free(data);
		}
	}
}

template<class NBR>
BaseVector<NBR>::BaseVector(NBR* data, size_t size):
	data(data), size(size)
{
	selfInit = false;
}

template<class NBR>
BaseVector<NBR>::BaseVector(size_t size)
{
	data = (NBR*)calloc(size,sizeof(NBR));
	this->size = size;
}

template<class NBR>
BaseVector<NBR>::BaseVector(BaseVector<NBR>& src)
{
	if (data) {
		if (selfInit) {
			free(data);
		}
	}
	data = (NBR*)malloc(src.size, sizeof(NBR));
	size = src.size;
	memcpy(data,src.data,size*sizeof(NBR));
}

template<class NBR>
inline NBR& BaseVector<NBR>::operator()(size_t index)
{
	if (data) {
		if (index < size) {
			return data[index];
		}
	}
}
