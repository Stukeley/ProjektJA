// Temat: Filtr g�rnoprzepustowy "HP1" dla obraz�w typu Bitmap.
// Opis: Algorytm nak�ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u�ytkownika przy pomocy interfejsu graficznego.
// Autor: Rafa� Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
// Wersja: 1.0.

int* Masks;

int SumOfMasks;

void InitializeMasks();

byte CalculateNewPixelValue(byte* imageFragment);

extern "C" __declspec(dllexport) byte* __stdcall ApplyFilterToImageFragmentCpp(byte * bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);