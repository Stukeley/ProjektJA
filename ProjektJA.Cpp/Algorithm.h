// Temat: Filtr g�rnoprzepustowy "HP1" dla obraz�w typu Bitmap.
// Opis: Algorytm nak�ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u�ytkownika przy pomocy interfejsu graficznego.
// Autor: Rafa� Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
// Wersja: 1.0.

// Wska�nik na tablic� 3x3 masek, inicjalizowan� przez funkcj� InitializeMasks.
int* Masks;

// Suma masek z tablicy Masks, obliczana przez funkcj� InitializeMasks.
int SumOfMasks;

// Funkcja inicjalizuj�ca tablic� Masks oraz ich sum� SumOfMasks odpowiednimi maskami filtra g�rnoprzepustowego HP1.
// http://www.algorytm.org/przetwarzanie-obrazow/filtrowanie-obrazow.html
// Maski:
// 0, -1, 0
// -1, 5, -1
// 0, -1, 0
void InitializeMasks();

// Funkcja obliczaj�ca now� warto�� piksela na podstawie tablicy 3x3, zawieraj�cej warto�ci R, G lub B dla fragmentu bitmapy.
// Przekazywanym parametrem jest wska�nik na tablic� 3x3, reprezentuj�c� piksele R, G lub B fragmentu obrazu.
// Warto�ci� zwracan� jest liczba z przedzia�u <0; 255>, reprezentuj�ca now� warto�� piksela �rodkowego w tablicy wej�ciowej w danym kolorze.
byte CalculateNewPixelValue(byte* imageFragment);

// Funkcja nak�adaj�ca na fragment bitmapy filtr g�rnoprzepustowy.
// Parametry wej�ciowe: bitmapa wej�ciowa, d�ugo�� bitmapy wej�ciowej, szeroko�� bitmapy wej�ciowej, pocz�tkowy indeks dla kt�rego ma pracowa� funkcja,
// ko�cowy indeks dla kt�rego ma pracowa� funkcja.
// Funkcja zwraca wska�nik na tablic� (stworzon� wewn�trz funkcji) zawieraj�c� fragment obrazu z na�o�onym filtrem.
extern "C" __declspec(dllexport) byte* __stdcall ApplyFilterToImageFragmentCpp(byte * bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);