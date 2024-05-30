using System;
using System.IO;
using System.Security;

namespace PasswordSetter
{
    class Program
    {
        // Define global variables
        private static string safeNetHouston = @"H:\dev_mabogan\DD_Script\";
        private static string s1FileName = "dd_dbpu_s1.Key";
        private static string s2FileName = "dd_dbpu_s2.Key";
        private static string split;
        private static SecureString half;

        static void Main(string[] args)
        {
            // Prompt for user input
            Console.Write("Which half? s1 or s2: ");
            split = Console.ReadLine();

            Console.Write("Enter password half: ");
            half = GetSecureStringFromConsole();

            // Validate parameters and handle the input
            ValidateParameters();
        }

        static void ValidateParameters()
        {
            switch (split)
            {
                case "s1":
                    if (half.Length != 12)
                    {
                        Console.WriteLine("s1 password length must equal 12");
                    }
                    else
                    {
                        SaveSecurePassword(half, Path.Combine(safeNetHouston, s1FileName));
                        Console.WriteLine("Password set successfully");
                    }
                    break;

                case "s2":
                    if (half.Length != 13)
                    {
                        Console.WriteLine("s2 password length must equal 13");
                    }
                    else
                    {
                        SaveSecurePassword(half, Path.Combine(safeNetHouston, s2FileName));
                        Console.WriteLine("Password set successfully");
                    }
                    break;

                default:
                    Console.WriteLine("Incorrect input");
                    Console.WriteLine("Enter s1 or s2 at which half? prompt, password at password prompt");
                    break;
            }
        }

        static SecureString GetSecureStringFromConsole()
        {
            SecureString secureString = new SecureString();
            while (true)
            {
                ConsoleKeyInfo keyInfo = Console.ReadKey(intercept: true);
                if (keyInfo.Key == ConsoleKey.Enter)
                    break;
                if (keyInfo.Key == ConsoleKey.Backspace && secureString.Length > 0)
                {
                    secureString.RemoveAt(secureString.Length - 1);
                    Console.Write("\b \b");
                }
                else if (!char.IsControl(keyInfo.KeyChar))
                {
                    secureString.AppendChar(keyInfo.KeyChar);
                    Console.Write("*");
                }
            }
            secureString.MakeReadOnly();
            Console.WriteLine();
            return secureString;
        }

        static void SaveSecurePassword(SecureString secureString, string filePath)
        {
            IntPtr bstr = Marshal.SecureStringToBSTR(secureString);
            try
            {
                string encryptedPassword = Marshal.PtrToStringBSTR(bstr);
                File.WriteAllText(filePath, encryptedPassword);
            }
            finally
            {
                Marshal.ZeroFreeBSTR(bstr);
            }
        }
    }
}
