// Temat: Filtr górnoprzepustowy "HP1" dla obrazów typu Bitmap.
// Opis: Algorytm nakłada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez użytkownika przy pomocy interfejsu graficznego.
// Autor: Rafał Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
// Wersja: 1.0.

using Microsoft.Win32;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
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

				// Ładujemy bitmapę jako tablicę bajtów.
				var bitmapBytes = File.ReadAllBytes(_filePath);
				_bitmapBytes = bitmapBytes;

				// Pokazanie bitmapy wejściowej na ekranie.
				var bitmapImage = ConvertBitmapBytesToImageSource(bitmapBytes);
				var image = new Image()
				{
					Source = bitmapImage,
					Width = 200,
					Height = 200
				};

				var textBlock = new TextBlock()
				{
					Text = "Wejście",
					Margin = new Thickness(0, 0, 0, 10),
					HorizontalAlignment = HorizontalAlignment.Center,
					FontWeight = FontWeights.Bold
				};

				var panel = new StackPanel();
				panel.Children.Add(textBlock);
				panel.Children.Add(image);

				ContentPanel.Children.Add(panel);

				FilterBitmapButton.IsEnabled = true;
				SaveBitmapButton.IsEnabled = false;
			}

		}

		private void FilterBitmapButton_Click(object sender, RoutedEventArgs e)
		{
			_threadCount = int.Parse(ThreadCountBox.Text);

			if (_threadCount > MaximumThreadCount)
			{
				MessageBox.Show($"Maksymalna ilość wątków to {MaximumThreadCount}.", "Zbyt dużo wątków", MessageBoxButton.OK, MessageBoxImage.Warning);
				_threadCount = MaximumThreadCount;
				ThreadCountBox.Text = $"{MaximumThreadCount}";
			}
			else if (_threadCount <= 0)
			{
				MessageBox.Show($"Minimalna ilość wątków to 1.", "Ilość wątków ustawiona na 0 lub mniej", MessageBoxButton.OK, MessageBoxImage.Warning);
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

			byte[] result = null;

			if (_asmAlgorithm)
			{
				result = Algorithms.CallAsmAlgorithm(bitmapWithoutHeader, bitmapWidth, _threadCount).Result;
			}
			else
			{
				result = Algorithms.CallCppAlgorithm(bitmapWithoutHeader, bitmapWidth, _threadCount).Result;
			}

			_stopwatch.Stop();
			string executionTime = "Czas wykonania: " + _stopwatch.Elapsed.ToString(@"mm\:ss\.fff");
			ExecutionTimeBlock.Text = executionTime;

			// Rekonstrukcja nagłówka bitmapy.
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

			// Wyświetlenie obrazu z nałożonym filtrem na ekranie.
			var bitmapImage = ConvertBitmapBytesToImageSource(outputBitmapComplete);
			var image = new Image()
			{
				Source = bitmapImage,
				Width = 200,
				Height = 200
			};

			// Identyfikator obrazu
			var textBlock = new TextBlock()
			{
				Text = $"{_threadCount}t: {(_asmAlgorithm ? "ASM" : "C++")}, {executionTime}",
				Margin = new Thickness(0, 0, 0, 10),
				HorizontalAlignment = HorizontalAlignment.Center,
				FontWeight = FontWeights.Bold
			};

			var panel = new StackPanel() { Margin = new Thickness(10, 0, 0, 0) };

			panel.Children.Add(textBlock);
			panel.Children.Add(image);

			ContentPanel.Children.Add(panel);

			_outputBitmapBytes = outputBitmapComplete;

			SaveBitmapButton.IsEnabled = true;

			// Tylko w trybie DEBUG - zapisanie obrazu.
#if DEBUG
			File.WriteAllBytes("TestOutput.bmp", outputBitmapComplete);

			var dobra = HighPassImageFilter.ApplyFilterToImageFragmentCs(bitmapWithoutHeader, bitmapWithoutHeader.Length, bitmapWidth, 0, bitmapWithoutHeader.Length - 1);

			CompareTwoArrays(result, dobra);
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

			MessageBox.Show("Obraz zapisany do ścieżki wyjściowej projektu!");
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
