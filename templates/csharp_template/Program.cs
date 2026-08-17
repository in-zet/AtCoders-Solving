using System;
using System.IO;

class Program
{
    static StreamReader sr = new StreamReader(new BufferedStream(Console.OpenStandardInput()));
    static StreamWriter sw = new StreamWriter(new BufferedStream(Console.OpenStandardOutput()));
    static void Main()
    {
        int n = ReadInt();
        string res = "";
        for (int i = 0; i < n; i++)
        {
            res = $"{ReadInt() + ReadInt()}";
            sw.WriteLine(res);
        }

        sw.Flush();
        return;
    }
    static int ReadInt()
    {
        int r = 0, c;
        bool neg = false;

        while ((c = sr.Read()) < '0' || c > '9')
            if (c == '-') neg = true;

        do
        {
            r = r * 10 + (c - '0');
        }
        while ((c = sr.Read()) >= '0' && c <= '9');

        return neg ? -r : r;
    }
}