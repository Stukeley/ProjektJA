// Temat: Filtr górnoprzepustowy "HP1" dla obrazów typu Bitmap.
// Opis: Algorytm nak³ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u¿ytkownika przy pomocy interfejsu graficznego.
// Autor: Rafa³ Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
// Wersja: 1.0.

// WskaŸnik na tablicê 3x3 masek, inicjalizowan¹ przez funkcjê InitializeMasks.
int* Masks;

// Suma masek z tablicy Masks, obliczana przez funkcjê InitializeMasks.
int SumOfMasks;

// Funkcja inicjalizuj¹ca tablicê Masks oraz ich sumê SumOfMasks odpowiednimi maskami filtra górnoprzepustowego HP1.
// http://www.algorytm.org/przetwarzanie-obrazow/filtrowanie-obrazow.html
// Maski:
// 0, -1, 0
// -1, 5, -1
// 0, -1, 0
void InitializeMasks();

// Funkcja obliczaj¹ca now¹ wartoœæ piksela na podstawie tablicy 3x3, zawieraj¹cej wartoœci R, G lub B dla fragmentu bitmapy.
// Przekazywanym parametrem jest wskaŸnik na tablicê 3x3, reprezentuj¹c¹ piksele R, G lub B fragmentu obrazu.
// Wartoœci¹ zwracan¹ jest liczba z przedzia³u <0; 255>, reprezentuj¹ca now¹ wartoœæ piksela œrodkowego w tablicy wejœciowej w danym kolorze.
byte CalculateNewPixelValue(byte* imageFragment);

// Funkcja nak³adaj¹ca na fragment bitmapy filtr górnoprzepustowy.
// Parametry wejœciowe: bitmapa wejœciowa, d³ugoœæ bitmapy wejœciowej, szerokoœæ bitmapy wejœciowej, pocz¹tkowy indeks dla którego ma pracowaæ funkcja,
// koñcowy indeks dla którego ma pracowaæ funkcja.
// Funkcja zwraca wskaŸnik na tablicê (stworzon¹ wewn¹trz funkcji) zawieraj¹c¹ fragment obrazu z na³o¿onym filtrem.
extern "C" __declspec(dllexport) byte* __stdcall ApplyFilterToImageFragmentCpp(byte * bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);