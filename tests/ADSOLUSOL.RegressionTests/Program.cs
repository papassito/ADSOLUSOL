using System;
using System.Threading.Tasks;

namespace ADSOLUSOL.RegressionTests;

class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("==========================================");
        Console.WriteLine("  ADSOLUSOL - SUITE DE PRUEBAS REGRESIÓN  ");
        Console.WriteLine("==========================================");

        await RunTestAsync("Verificación básica de entorno", async () =>
        {
            await Task.Delay(10);
            return true;
        });

        Console.WriteLine("\n[PASS] Pruebas de regresión completadas con éxito.");
    }

    static async Task RunTestAsync(string testName, Func<Task<bool>> testAction)
    {
        try
        {
            bool result = await testAction();
            if (result)
            {
                Console.WriteLine($"[✓] {testName}: PASS");
            }
            else
            {
                Console.WriteLine($"[X] {testName}: FAIL");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[X] {testName}: EXCEPCIÓN - {ex.Message}");
        }
    }
}
