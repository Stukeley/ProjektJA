// dllmain.cpp : Defines the entry point for the DLL application.
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

typedef int(__stdcall* f_MyProc1)(DWORD, DWORD);

extern "C" __declspec(dllexport) int RunAsm()
{
	HINSTANCE hGetProcIDDLL = LoadLibrary(L"C:\\Programowanie\\ProjektJA\\x64\\Debug\\ProjektJA.Asm.dll");

	if (hGetProcIDDLL == NULL)
	{
		// Nie mozna bylo zaladowac DLL.
		return 0;
	}

	f_MyProc1 MyProc1 = (f_MyProc1)GetProcAddress(hGetProcIDDLL, "MyProc1");

	if (!MyProc1)
	{
		// Nie znaleziono procedury w DLL.
		return 0;
	}

	int x = 1, y = 2;

	int z = MyProc1(x, y);

	FreeLibrary(hGetProcIDDLL);

	return z;
}

extern "C" __declspec(dllexport) int RunCpp()
{
	int x = 1, y = 2;

	int z = Add(x, y);

	return z;
}