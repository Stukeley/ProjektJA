using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace ProjektJA.UI
{
	public class Algorithms
	{
		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Asm.dll")]
		public static extern IntPtr ApplyFilterToImageFragmentAsm(IntPtr bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex, IntPtr filteredFragment);

		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Cpp.dll", CallingConvention = CallingConvention.StdCall)]
		public static extern IntPtr ApplyFilterToImageFragmentCpp(IntPtr bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);

		// test
		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Asm.dll")]
		public static extern int CalculateNewPixelValue(IntPtr bitmapBytes);

		// Funkcja pomocnicza testująca algorytm w C#.
		public static async Task<byte[]> CallCsAlgorithm(byte[] bitmapBytes, int bitmapWidth, int threadCount)
		{
			var listOfTasks = new List<Task<byte[]>>();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			bytesPerPart -= bytesPerPart % 3;

			for (int i = 0; i < threadCount; i++)
			{
				int startIndex = index;
				int endIndex = startIndex + bytesPerPart - 1;

				if (i == threadCount - 1)
				{
					endIndex = bitmapBytes.Length - 1;
				}

				index = endIndex + 1;

				byte[] bitmapCopy = new byte[bitmapBytes.Length];

				for (int j = 0; j < bitmapBytes.Length; j++)
				{
					bitmapCopy[j] = bitmapBytes[j];
				}

				var task = Task.Run(() => HighPassImageFilter.ApplyFilterToImageFragmentCs(bitmapCopy, bitmapBytes.Length, bitmapWidth, startIndex, endIndex));
				listOfTasks.Add(task);

				//unsafe
				//{
				//	fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
				//	{
				//		var intPtr = new IntPtr(pointerToByteArray);

				//		var task = Task.Run(() => HighPassImageFilter.ApplyFilterToImageFragmentCs(intPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex));
				//		listOfTasks.Add(task);
				//	}
				//}
			}

			await Task.WhenAll(listOfTasks).ConfigureAwait(false);

			var output = new byte[bitmapBytes.Length];
			index = 0;

			foreach (var task in listOfTasks)
			{
				byte[] outputPart = task.Result;

				for (int i = 0; i < outputPart.Length; i++)
				{
					output[index++] = outputPart[i];
				}
			}

			return output;
		}

		public static async Task<byte[]> CallCppAlgorithm(byte[] bitmapBytes, int bitmapWidth, int threadCount)
		{
			var listOfTasks = new List<Task<IntPtr>>();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			bytesPerPart -= bytesPerPart % 3;

			for (int i = 0; i < threadCount; i++)
			{
				int startIndex = index;
				int endIndex = startIndex + bytesPerPart - 1;

				if (i == threadCount - 1)
				{
					endIndex = bitmapBytes.Length - 1;
				}

				index = endIndex + 1;

				byte[] bitmapCopy = new byte[bitmapBytes.Length];

				for (int j = 0; j < bitmapBytes.Length; j++)
				{
					bitmapCopy[j] = bitmapBytes[j];
				}

				unsafe
				{
					fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
					{
						var intPtr = new IntPtr(pointerToByteArray);

						var task = Task.Run(() => ApplyFilterToImageFragmentCpp(intPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex));
						listOfTasks.Add(task);
					}
				}
			}

			await Task.WhenAll(listOfTasks).ConfigureAwait(false);

			var output = new byte[bitmapBytes.Length];
			index = 0;

			for (int i = 0; i < listOfTasks.Count; i++)
			{
				var task = listOfTasks[i];
				int partSize = bytesPerPart;

				if (i == listOfTasks.Count - 1)
				{
					partSize = bitmapBytes.Length - (listOfTasks.Count - 1) * bytesPerPart;
				}

				unsafe
				{
					byte* outputPart = (byte*)task.Result;

					for (int j = 0; j < partSize; j++)
					{
						output[index++] = outputPart[j];
					}
				}
			}

			return output;
		}

		public static async Task<byte[]> CallAsmAlgorithm(byte[] bitmapBytes, int bitmapWidth, int threadCount)
		{
			var listOfTasks = new List<Task<IntPtr>>();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			bytesPerPart -= bytesPerPart % 3;

			for (int i = 0; i < threadCount; i++)
			{
				int startIndex = index;
				int endIndex = startIndex + bytesPerPart - 1;

				if (i == threadCount - 1)
				{
					endIndex = bitmapBytes.Length - 1;
				}

				index = endIndex + 1;

				byte[] bitmapCopy = new byte[bitmapBytes.Length];

				for (int j = 0; j < bitmapBytes.Length; j++)
				{
					bitmapCopy[j] = bitmapBytes[j];
				}

				byte[] filteredFragment = new byte[endIndex - startIndex + 1];

				for (int x = 0; x < endIndex - startIndex + 1; x++)
				{
					filteredFragment[x] = bitmapBytes[startIndex + x];
				}

				unsafe
				{
					fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
					fixed (byte* pointerToFilteredFragmentArray = &(filteredFragment[0]))
					{
						var bitmapBytesIntPtr = new IntPtr(pointerToByteArray);
						var filteredFragmentIntPtr = new IntPtr(pointerToFilteredFragmentArray);

						var task = Task.Run(() => ApplyFilterToImageFragmentAsm(bitmapBytesIntPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex, filteredFragmentIntPtr));
						listOfTasks.Add(task);
					}
				}
			}

			await Task.WhenAll(listOfTasks).ConfigureAwait(false);

			var output = new byte[bitmapBytes.Length];
			index = 0;

			for (int i = 0; i < listOfTasks.Count; i++)
			{
				var task = listOfTasks[i];
				int partSize = bytesPerPart;

				if (i == listOfTasks.Count - 1)
				{
					partSize = bitmapBytes.Length - (listOfTasks.Count - 1) * bytesPerPart;
				}

				unsafe
				{
					byte* outputPart = (byte*)task.Result;

					for (int j = 0; j < partSize; j++)
					{
						output[index++] = outputPart[j];
					}
				}
			}

			return output;
		}

		public static void TestAsmAlgorithm(byte[] bitmapBytes, int bitmapWidth)
		{
			int centerPixelIndex = 500;
			var valuesR = new byte[9];
			var valuesG = new byte[9];
			var valuesB = new byte[9];

			for (int y = 0; y < 3; y++)
			{
				for (int x = 0; x < 3; x++)
				{
					var index = centerPixelIndex + (bitmapWidth * (y - 1) + (x - 1) * 3);

					valuesR[x + y * 3] = bitmapBytes[index];
					valuesG[x + y * 3] = bitmapBytes[index + 1];
					valuesB[x + y * 3] = bitmapBytes[index + 2];
				}
			}

			int newR_CS = HighPassImageFilter.CalculateNewPixelValue(valuesR);
			int newG_CS = HighPassImageFilter.CalculateNewPixelValue(valuesG);
			int newB_CS = HighPassImageFilter.CalculateNewPixelValue(valuesB);

			int newR_ASM;
			int newG_ASM;
			int newB_ASM;

			unsafe
			{
				fixed (byte* r = &(valuesR[0]))
				{
					newR_ASM = CalculateNewPixelValue(new IntPtr(r));
				}

				fixed (byte* g = &(valuesG[0]))
				{
					newG_ASM = CalculateNewPixelValue(new IntPtr(g));
				}

				fixed (byte* b = &(valuesB[0]))
				{
					newB_ASM = CalculateNewPixelValue(new IntPtr(b));
				}
			}

			bool eq1 = newR_CS == newR_ASM;
			bool eq2 = newG_CS == newG_ASM;
			bool eq3 = newB_CS == newB_ASM;
		}
	}
}
