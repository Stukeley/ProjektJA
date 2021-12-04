using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace ProjektJA.UI
{
	public class Algorithms
	{
		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Asm.dll")]
		public static extern int ApplyFilterToImageFragmentAsm(IntPtr bitmapBytes, int bitmapBytesLength, int startIndex, int endIndex);

		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Cpp.dll", CallingConvention = CallingConvention.StdCall)]
		public static extern IntPtr ApplyFilterToImageFragmentCpp(IntPtr bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);

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
	}
}
