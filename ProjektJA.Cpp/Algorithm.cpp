// Temat: Filtr górnoprzepustowy "HP1" dla obrazów typu Bitmap.
// Opis: Algorytm nak³ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u¿ytkownika przy pomocy interfejsu graficznego.
// Autor: Rafa³ Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
// Wersja: 1.0.

#include "pch.h"
#include "Algorithm.h"

void InitializeMasks()
{
	SumOfMasks = 1;

	Masks = new int[9]
	{
		0, -1, 0,
		-1, 5, -1,
		0, -1, 0
	};
}

extern "C" __declspec(dllexport) byte* __stdcall ApplyFilterToImageFragmentCpp(byte* bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex)
{
	InitializeMasks();

	byte* filteredFragment = new byte[endIndex - startIndex + 1];

	for (int i = 0; i < endIndex - startIndex + 1; i++)
	{
		filteredFragment[i] = bitmapBytes[startIndex + i];
	}

	for (int i = startIndex; i <= endIndex; i += 3)
	{
		int centerPixelIndex = i;

		if (centerPixelIndex < bitmapWidth)
		{
			// Górna krawêdŸ bitmapy.
			continue;
		}
		if (i % bitmapWidth == 0)
		{
			// Lewa krawêdŸ bitmapy.
			continue;
		}
		if (i >= bitmapBytesLength - bitmapWidth)
		{
			// Dolna krawêdŸ bitmapy.
			continue;
		}
		if ((i + 2 + 1) % bitmapWidth == 0)
		{
			// Prawa krawêdŸ bitmapy.
			continue;
		}

		byte* valuesR = new byte[9];
		byte* valuesG = new byte[9];
		byte* valuesB = new byte[9];

		for (int y = 0; y < 3; y++)
		{
			for (int x = 0; x < 3; x++)
			{
				int index = centerPixelIndex + (bitmapWidth * (y - 1) + (x - 1) * 3);

				valuesR[x + y * 3] = bitmapBytes[index];
				valuesG[x + y * 3] = bitmapBytes[index + 1];
				valuesB[x + y * 3] = bitmapBytes[index + 2];
			}
		}

		filteredFragment[i - startIndex] = CalculateNewPixelValue(valuesR);
		filteredFragment[i - startIndex + 1] = CalculateNewPixelValue(valuesG);
		filteredFragment[i - startIndex + 2] = CalculateNewPixelValue(valuesB);

		delete [] valuesR;
		delete [] valuesG;
		delete [] valuesB;
	}

	return filteredFragment;
}

byte CalculateNewPixelValue(byte* imageFragment)
{
	int newPixelWeightedValue = 0;

	for (int y = 0; y < 3; y++)
	{
		for (int x = 0; x < 3; x++)
		{
			int factor = imageFragment[x + y * 3] * Masks[x + y * 3];

			newPixelWeightedValue += factor;
		}
	}

	if (newPixelWeightedValue < 0)
	{
		newPixelWeightedValue = 0;
	}
	else if (newPixelWeightedValue > 255)
	{
		newPixelWeightedValue = 255;
	}

	return (byte)(newPixelWeightedValue / (float)SumOfMasks);
}