using Microsoft.Win32;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Media.Imaging;

namespace ProjektJA.UI
{
	public partial class MainWindow : Window
	{
		private const int MaximumThreadCount = 16;

		private bool _asmAlgorithm;
		private string _filePath;
		private Stopwatch _stopwatch;
		private int _threadCount;
		private byte[] _bitmapBytes;
		private byte[] _outputBitmapBytes;

		public MainWindow()
		{
			InitializeComponent();

			CsAlgorithmBox.IsChecked = true;
			_asmAlgorithm = false;
			_stopwatch = new Stopwatch();
		}

		private void FileBrowserButton_Click(object sender, RoutedEventArgs e)
		{
			var openFileDialog = new OpenFileDialog()
			{
				Filter = "Bitmap files (*.bmp)|*.bmp|All files (*.*)|*.*",
				InitialDirectory = Directory.GetCurrentDirectory()
			};

			if (openFileDialog.ShowDialog() == true)
			{
				var fileName = openFileDialog.FileName;

				if (Path.GetExtension(fileName) != ".bmp")
				{
					MessageBox.Show("A file with an incorrect extension has been selected. This program only accepts bitmap (.bmp) files.", "Wrong file extension", MessageBoxButton.OK, MessageBoxImage.Warning);
					return;
				}

				ContentPanel.Children.Clear();
				ExecutionTimeBlock.Text = "";

				FilePathBox.Text = fileName;
				_filePath = fileName;

				// Load bitmap as byte array.
				var bitmapBytes = File.ReadAllBytes(_filePath);
				_bitmapBytes = bitmapBytes;

				// Display input bitmap on screen.
				var bitmapImage = ConvertBitmapBytesToImageSource(bitmapBytes);
				var image = new System.Windows.Controls.Image()
				{
					Source = bitmapImage,
					Width = 200,
					Height = 200
				};
				ContentPanel.Children.Add(image);

				FilterBitmapButton.IsEnabled = true;
				SaveBitmapButton.IsEnabled = false;
			}

		}

		private void FilterBitmapButton_Click(object sender, RoutedEventArgs e)
		{
			_threadCount = int.Parse(ThreadCountBox.Text);

			if (_threadCount > MaximumThreadCount)
			{
				MessageBox.Show($"The maximum amount of threads is {MaximumThreadCount}.", "Too many threads", MessageBoxButton.OK, MessageBoxImage.Warning);
				_threadCount = MaximumThreadCount;
				ThreadCountBox.Text = $"{MaximumThreadCount}";
			}
			else if (_threadCount <= 0)
			{
				MessageBox.Show($"The minimum amount of threads is 1.", "Threads set to 0 or less", MessageBoxButton.OK, MessageBoxImage.Warning);
				_threadCount = 1;
				ThreadCountBox.Text = "1";
			}

			var bitmapHeader = _bitmapBytes.Take(54).ToArray();

			var bitmapWithoutHeader = new byte[_bitmapBytes.Length - 54];

			for (int i = 54; i < _bitmapBytes.Length; i++)
			{
				bitmapWithoutHeader[i - 54] = _bitmapBytes[i];
			}

			int bitmapWidth = BitConverter.ToInt32(bitmapHeader.Skip(18).Take(4).ToArray(), 0) * 3;

			_stopwatch.Restart();

			byte[] result = Algorithms.CallAlgorithm(bitmapWithoutHeader, bitmapWidth,_threadCount,_asmAlgorithm).Result;

			// var resultCs = Algorithms.CallCsAlgorithm(bitmapWithoutHeader, bitmapWidth, _threadCount).Result;
			//
			// CompareTwoArrays(result, resultCs);

			_stopwatch.Stop();
			string executionTime = "Execution time: " + _stopwatch.Elapsed.ToString(@"mm\:ss\.fff");
			ExecutionTimeBlock.Text = executionTime;

			// Reconstruct bitmap header.
			var outputBitmapComplete = new byte[_bitmapBytes.Length];
			int x = 0;

			for (x = 0; x < 54; x++)
			{
				outputBitmapComplete[x] = bitmapHeader[x];
			}

			for (x = 54; x < outputBitmapComplete.Length; x++)
			{
				outputBitmapComplete[x] = result[x - 54];
			}

			// Display output bitmap on screen.
			var bitmapImage = ConvertBitmapBytesToImageSource(outputBitmapComplete);
			var image = new System.Windows.Controls.Image()
			{
				Source = bitmapImage,
				Width = 200,
				Height = 200,
				Margin = new Thickness(10, 0, 0, 0)
			};
			ContentPanel.Children.Add(image);

			_outputBitmapBytes = outputBitmapComplete;

			// Allow the output image to be saved.
			SaveBitmapButton.IsEnabled = true;

			// Debug only - save the image separately.
#if DEBUG
			File.WriteAllBytes("TestOutput.bmp", outputBitmapComplete);
#endif
		}

		private static void CompareTwoArrays(byte[] first, byte[] second)
		{
			// second jest dobra (wzięta z C#)

			bool[] compared = new bool[first.Length];

			for (int i = 0; i < first.Length; i++)
			{
				if (first[i] == second[i])
				{
					compared[i] = true;
				}
				else
				{
					compared[i] = false;
				}
			}

			int trueCount = compared.Count(x => x == true);
			int falseCount = compared.Count(x => x == false);

			// Export to file

			using (var writer = new StreamWriter("TempOutput_Zla.txt"))
			{
				for (int i = 0; i < first.Length; i++)
				{
					writer.WriteLine(first[i]);
				}
			}

			using (var writer = new StreamWriter("TempOutput_Dobra.txt"))
			{
				for (int i = 0; i < second.Length; i++)
				{
					writer.WriteLine(second[i]);
				}
			}
		}

		private static BitmapImage ConvertBitmapBytesToImageSource(byte[] bitmapBytes)
		{
			if (bitmapBytes is null)
			{
				return null;
			}

			var copy = new byte[bitmapBytes.Length];

			for (int i = 0; i < bitmapBytes.Length; i++)
			{
				copy[i] = bitmapBytes[i];
			}

			var bmp = new BitmapImage();
			var ms = new MemoryStream(bitmapBytes);
			bmp.BeginInit();
			bmp.StreamSource = ms;
			bmp.CacheOption = BitmapCacheOption.OnLoad;
			bmp.EndInit();

			return bmp;
		}

		private void SaveBitmapButton_Click(object sender, RoutedEventArgs e)
		{
			File.WriteAllBytes("Output.bmp", _outputBitmapBytes);
		}

		private void AsmAlgorithmBox_Unchecked(object sender, RoutedEventArgs e)
		{
			CsAlgorithmBox.IsChecked = true;
			_asmAlgorithm = false;
		}

		private void CsAlgorithmBox_Unchecked(object sender, RoutedEventArgs e)
		{
			AsmAlgorithmBox.IsChecked = true;
			_asmAlgorithm = true;
		}

		private void AsmAlgorithmBox_Checked(object sender, RoutedEventArgs e)
		{
			CsAlgorithmBox.IsChecked = false;
			_asmAlgorithm = true;
		}

		private void CsAlgorithmBox_Checked(object sender, RoutedEventArgs e)
		{
			AsmAlgorithmBox.IsChecked = false;
			_asmAlgorithm = false;
		}
	}
}
