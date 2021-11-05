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
		public static extern int ApplyFilterToImageFragmentCpp(IntPtr bitmapBytes, int bitmapBytesLength, int startIndex, int endIndex);

		public static async Task<byte[]> CallAsmAlgorithm(byte[] bitmapBytes, int threadCount)
		{
			var listOfTasks = new List<Task>();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			// Control sum
			int sumOfTenBytes = 0;

			for (int i = 0; i < 10; i++)
			{
				sumOfTenBytes += bitmapBytes[i];
			}

			for (int i = 0; i < threadCount; i++)
			{
				int startIndex = index;
				int endIndex = startIndex + bytesPerPart;

				if (i == threadCount - 1)
				{
					endIndex = bitmapBytes.Length - 1;
				}

				unsafe
				{
					fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
					{
						var intPtr = new IntPtr(pointerToByteArray);

						var task = Task.Run(() => ApplyFilterToImageFragmentAsm(intPtr, bitmapBytes.Length, startIndex, endIndex));
						listOfTasks.Add(task);
					}
				}
			}

			await Task.WhenAll(listOfTasks);

			int sumAsm = ((Task<int>)listOfTasks[0]).Result;

			return new byte[1];
		}

		public static async Task<byte[]> CallCppAlgorithm(byte[] bitmapBytes, int threadCount)
		{
			var listOfTasks = new List<Task>();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			// Control sum
			int sumOfTenBytes = 0;

			for (int i = 0; i < 10; i++)
			{
				sumOfTenBytes += bitmapBytes[i];
			}

			for (int i = 0; i < threadCount; i++)
			{
				int startIndex = index;
				int endIndex = startIndex + bytesPerPart;

				if (i == threadCount - 1)
				{
					endIndex = bitmapBytes.Length - 1;
				}

				unsafe
				{
					fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
					{
						var intPtr = new IntPtr(pointerToByteArray);

						var task = Task.Run(() => ApplyFilterToImageFragmentCpp(intPtr, bitmapBytes.Length, startIndex, endIndex));
						listOfTasks.Add(task);
					}
				}
			}

			await Task.WhenAll(listOfTasks);

			int sumAsm = ((Task<int>)listOfTasks[0]).Result;

			return new byte[1];
		}
	}
}
