using Microsoft.Win32;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace ProjektJA.UI
{
	public partial class MainWindow : Window
	{
		private bool _asmAlgorithm;
		private string _filePath;
		private Stopwatch _stopwatch;
		private int _threadCount;
		private byte[] _bitmapBytes;

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
				SaveBitmapButton.IsEnabled = false;
				ExecutionTimeBlock.Text = "";

				FilePathBox.Text = fileName;
				_filePath = fileName;

				// Load bitmap as byte array.
				var bitmapBytes = File.ReadAllBytes(_filePath);
				_bitmapBytes = bitmapBytes;

				//_bitmap = BitmapConverter.LoadBitmap(fileName);

				//ContentPanel.Children.Add(new System.Windows.Controls.Image()
				//{
				//	Source = ConvertBitmapToImageSource(_bitmap),
				//	Width = _bitmap.Width,
				//	Height = _bitmap.Height
				//});
				FilterBitmapButton.IsEnabled = true;
				SaveBitmapButton.IsEnabled = false;
			}

		}

		private void FilterBitmapButton_Click(object sender, RoutedEventArgs e)
		{
			_threadCount = int.Parse(ThreadCountBox.Text);

			var bitmapHeader = _bitmapBytes.Take(54);

			var bitmapWithoutHeader = new byte[_bitmapBytes.Length - 54];

			for (int i = 54; i < _bitmapBytes.Length; i++)
			{
				bitmapWithoutHeader[i - 54] = _bitmapBytes[i];
			}

			_stopwatch.Restart();

			if (_asmAlgorithm)
			{
				Algorithms.CallAsmAlgorithm(bitmapWithoutHeader, _threadCount);
			}
			else
			{
				Algorithms.CallCppAlgorithm(bitmapWithoutHeader, _threadCount);
			}

			_stopwatch.Stop();
			string _executionTime = "Execution time: " + _stopwatch.Elapsed.ToString(@"mm\:ss\.fff");
			ExecutionTimeBlock.Text = _executionTime;
		}


		private static ImageSource ConvertBitmapToImageSource(Bitmap bitmap)
		{
			if (bitmap is null)
			{
				return null;
			}

			using (var memoryStream = new MemoryStream())
			{
				bitmap.Save(memoryStream, ImageFormat.Bmp);
				memoryStream.Position = 0;
				var bitmapimage = new BitmapImage();
				bitmapimage.BeginInit();
				bitmapimage.StreamSource = memoryStream;
				bitmapimage.CacheOption = BitmapCacheOption.OnLoad;
				bitmapimage.EndInit();

				return bitmapimage;
			}
		}

		private void SaveBitmapButton_Click(object sender, RoutedEventArgs e)
		{
			// todo
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
