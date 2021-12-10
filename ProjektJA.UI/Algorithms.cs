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

		public static async Task<byte[]> CallAlgorithm(byte[] bitmapBytes, int bitmapWidth, int threadCount, bool asmAlgorithm)
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

				byte[] filteredFragment = new byte[endIndex - startIndex + 1];

				for (int x = 0; x < endIndex - startIndex + 1; x++)
				{
					filteredFragment[x] = bitmapBytes[startIndex + x];
				}

				Task<byte[]> task;

				if (asmAlgorithm)
				{
					task = Task.Run(() => CallApplyFilterToImageFragmentAsm(bitmapCopy, bitmapWidth, startIndex, endIndex, filteredFragment));
					task.Wait();
				}
				else
				{
					task = Task.Run(() => CallApplyFilterToImageFragmentCpp(bitmapCopy, bitmapWidth, startIndex, endIndex));
				}
				
				listOfTasks.Add(task);
			}

			await Task.WhenAll(listOfTasks).ConfigureAwait(false);

			var output = new byte[bitmapBytes.Length];
			index = 0;

			for (int i = 0; i < listOfTasks.Count; i++)
			{
				var task = listOfTasks[i];
				var taskResult = task.Result;

				for (int j = 0; j < taskResult.Length; j++)
				{
					output[index++] = taskResult[j];
				}
			}

			return output;
		}
		
		private static byte[] CallApplyFilterToImageFragmentAsm(byte[] bitmapBytes, int bitmapWidth, int startIndex, int endIndex, byte[] filteredFragment)
		{
			byte[] output = null;
			
			unsafe
			{
				fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
				fixed (byte* pointerToFilteredFragmentArray = &(filteredFragment[0]))
				{
					var bitmapBytesIntPtr = new IntPtr(pointerToByteArray);
					var filteredFragmentIntPtr = new IntPtr(pointerToFilteredFragmentArray);
					
					var result = ApplyFilterToImageFragmentAsm(bitmapBytesIntPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex, filteredFragmentIntPtr);

					byte* resultPointer = (byte*) result;

					output = new byte[endIndex - startIndex + 1];

					for (int i = 0; i < output.Length; i++)
					{
						output[i] = resultPointer[i];
					}
				}
			}

			return output;
		}

		private static byte[] CallApplyFilterToImageFragmentCpp(byte[] bitmapBytes, int bitmapWidth, int startIndex, int endIndex)
		{
			byte[] output = null;
			
			unsafe
			{
				fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
				{
					var bitmapBytesIntPtr = new IntPtr(pointerToByteArray);
					
					var result = ApplyFilterToImageFragmentCpp(bitmapBytesIntPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex);

					byte* resultPointer = (byte*) result;

					output = new byte[endIndex - startIndex + 1];

					for (int i = 0; i < output.Length; i++)
					{
						output[i] = resultPointer[i];
					}
				}
			}

			return output;
		}
	}
}
