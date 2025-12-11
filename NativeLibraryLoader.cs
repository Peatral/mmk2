using System;
using Godot;
using System.IO;
using System.Runtime.InteropServices;

namespace godotkinect;


// This class will be autoloaded to run at startup.
public partial class NativeLibraryLoader : Node
{
    // Import the SetDllDirectory function from kernel32.dll
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetDllDirectory(string lpPathName);

    public override void _Ready()
    {
        // Use AppContext.BaseDirectory, which is the reliable way
        // to get the directory of the executing assembly.
        string baseDir = AppContext.BaseDirectory;

        if (!string.IsNullOrEmpty(baseDir))
        {
            // Add this directory to the OS's native DLL search path.
            SetDllDirectory(baseDir);
            GD.Print($"Native DLL search path set to: {baseDir}");
        }
        else
        {
            GD.PrintErr("Could not determine assembly base directory. Native DLLs (k4a.dll, etc.) may fail to load.");
        }
    }
}