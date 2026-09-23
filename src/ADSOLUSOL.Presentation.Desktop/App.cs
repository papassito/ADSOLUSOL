using System;
using Microsoft.Maui;
using Microsoft.Maui.Controls;

namespace ADSOLUSOL.Presentation.Desktop;

public class App : Microsoft.Maui.Controls.Application
{
    public App()
    {
        MainPage = new ContentPage();
    }
}

public class WinUIApp : MauiWinUIApplication
{
    protected override MauiApp CreateMauiApp() => MauiProgram.CreateMauiApp();
}

public static class Program
{
    [STAThread]
    public static void Main(string[] args)
    {
        WinRT.ComWrappersSupport.InitializeComWrappers();
        Microsoft.UI.Xaml.Application.Start((p) =>
        {
            var context = new Microsoft.UI.Dispatching.DispatcherQueueSynchronizationContext(
                Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread());
            System.Threading.SynchronizationContext.SetSynchronizationContext(context);
            new WinUIApp();
        });
    }
}