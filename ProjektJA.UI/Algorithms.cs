using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace ProjektJA.UI
{
	public class Algorithms
	{
		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Asm.dll")]
		public static extern IntPtr ApplyFilterToImageFragmentAsm(IntPtr bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex, IntPtr filteredFragment, IntPtr valuesR, IntPtr valuesG, IntPtr valuesB);

		[DllImport(@"C:\Programowanie\ProjektJA\x64\Debug\ProjektJA.Cpp.dll", CallingConvention = CallingConvention.StdCall)]
		public static extern IntPtr ApplyFilterToImageFragmentCpp(IntPtr bitmapBytes, int bitmapBytesLength, int bitmapWidth, int startIndex, int endIndex);

		private static volatile Dictionary<int, byte[]> _listOfResults = new Dictionary<int, byte[]>();
		private static object _lock = new object(); // Lock potrzebny do synchronizacji zapisywania wątków do Dictionary

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

		// Główna funkcja obsługująca tworzenie wątków i zsynchronizowanie ich wyników.
		public static async Task<byte[]> CallCppAlgorithm(byte[] bitmapBytes, int bitmapWidth, int threadCount)
		{
			var listOfTasks = new List<Task>();

			_listOfResults.Clear();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			bytesPerPart -= bytesPerPart % 3;

			for (int i = 0; i < threadCount; i++)
			{
				// Obliczenie fragmentu, dla którego ma pracować i-ty wątek.

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

				int threadId = i;

				var task = Task.Run(() => CallApplyFilterToImageFragmentCpp(bitmapCopy, bitmapWidth, startIndex, endIndex, threadId));

				listOfTasks.Add(task);

			}

			await Task.WhenAll(listOfTasks).ConfigureAwait(false);

			byte[] output = new byte[bitmapBytes.Length]; ;

			index = 0;

			// Ustawiamy wyniki w odpowiedniej kolejności.
			_listOfResults = _listOfResults.OrderBy(x => x.Key).ToDictionary(pair => pair.Key, pair => pair.Value);

			for (int i = 0; i < _listOfResults.Count; i++)
			{
				var resultPart = _listOfResults[i];

				for (int j = 0; j < resultPart.Length; j++)
				{
					output[index++] = resultPart[j];
				}
			}

			return output;
		}

		public static async Task<byte[]> CallAsmAlgorithm(byte[] bitmapBytes, int bitmapWidth, int threadCount)
		{
			var listOfTasks = new List<Task>();

			_listOfResults.Clear();

			int index = 0;
			int bytesPerPart = bitmapBytes.Length / threadCount;

			bytesPerPart -= bytesPerPart % 3;

			for (int i = 0; i < threadCount; i++)
			{
				// Obliczenie fragmentu, dla którego ma pracować i-ty wątek.

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

				int taskId = i;

				var task = Task.Run(() => CallApplyFilterToImageFragmentAsm(bitmapCopy, bitmapWidth, startIndex, endIndex, filteredFragment, taskId));

				listOfTasks.Add(task);
			}

			await Task.WhenAll(listOfTasks).ConfigureAwait(false);

			byte[] output = new byte[bitmapBytes.Length];

			index = 0;

			// Ustawiamy wyniki w odpowiedniej kolejności.
			_listOfResults = _listOfResults.OrderBy(x => x.Key).ToDictionary(pair => pair.Key, pair => pair.Value);

			for (int i = 0; i < _listOfResults.Count; i++)
			{
				var resultPart = _listOfResults[i];

				for (int j = 0; j < resultPart.Length; j++)
				{
					output[index++] = resultPart[j];
				}
			}

			return output;
		}

		private static void CallApplyFilterToImageFragmentAsm(byte[] bitmapBytes, int bitmapWidth, int startIndex, int endIndex, byte[] filteredFragment, int threadId)
		{
			byte[] output = null;
			byte[] valuesR = new byte[9];
			byte[] valuesG = new byte[9];
			byte[] valuesB = new byte[9];

			unsafe
			{
				fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
				fixed (byte* pointerToFilteredFragmentArray = &(filteredFragment[0]))
				fixed (byte* pointerToR = &(valuesR[0]))
				fixed (byte* pointerToG = &(valuesG[0]))
				fixed (byte* pointerToB = &(valuesB[0]))
				{
					var bitmapBytesIntPtr = new IntPtr(pointerToByteArray);
					var filteredFragmentIntPtr = new IntPtr(pointerToFilteredFragmentArray);
					var rIntPtr = new IntPtr(pointerToR);
					var gIntPtr = new IntPtr(pointerToG);
					var bIntPtr = new IntPtr(pointerToB);

					var result = ApplyFilterToImageFragmentAsm(bitmapBytesIntPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex, filteredFragmentIntPtr, rIntPtr, gIntPtr, bIntPtr);

					byte* resultPointer = (byte*)result;

					output = new byte[endIndex - startIndex + 1];

					for (int i = 0; i < output.Length; i++)
					{
						output[i] = resultPointer[i];
					}
				}
			}

			lock (_lock)
			{
				_listOfResults.Add(threadId, output);
			}
		}

		private static void CallApplyFilterToImageFragmentCpp(byte[] bitmapBytes, int bitmapWidth, int startIndex, int endIndex, int threadId)
		{
			byte[] output = null;

			unsafe
			{
				fixed (byte* pointerToByteArray = &(bitmapBytes[0]))
				{
					var bitmapBytesIntPtr = new IntPtr(pointerToByteArray);

					var result = ApplyFilterToImageFragmentCpp(bitmapBytesIntPtr, bitmapBytes.Length, bitmapWidth, startIndex, endIndex);

					byte* resultPointer = (byte*)result;

					output = new byte[endIndex - startIndex + 1];

					for (int i = 0; i < output.Length; i++)
					{
						output[i] = resultPointer[i];
					}
				}
			}

			lock (_lock)
			{
				_listOfResults.Add(threadId, output);
			}
		}
	}
}
