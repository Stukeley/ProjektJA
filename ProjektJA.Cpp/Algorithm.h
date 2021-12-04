int* Masks;

int SumOfMasks;

void InitializeMasks();

byte CalculateNewPixelValue(byte* imageFragment);

extern "C" __declspec(dllexport) byte* __stdcall ApplyFilterToImageFragmentCpp(byte * bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);