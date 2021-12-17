// Temat: Filtr górnoprzepustowy "HP1" dla obrazów typu Bitmap.
// Opis: Algorytm nak³ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u¿ytkownika przy pomocy interfejsu graficznego.
// Autor: Rafa³ Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
// Wersja: 1.0.

#include "pch.h"

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}