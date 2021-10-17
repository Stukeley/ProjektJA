using System.Windows;

namespace ProjektJA.UI
{
	public partial class MainWindow : Window
	{
		public MainWindow()
		{
			InitializeComponent();
		}

		private void RunCppButton_Click(object sender, RoutedEventArgs e)
		{
			int result = Algorithms.RunCpp();
			ResultBlock.Text = $"z = {result}";
		}

		private void RunAsmButton_Click(object sender, RoutedEventArgs e)
		{
			int result = Algorithms.RunAsm();
			ResultBlock.Text = $"z = {result}";
		}
	}
}
