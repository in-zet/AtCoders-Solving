using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

class Program
{
    static StreamReader sr = new StreamReader(new BufferedStream(Console.OpenStandardInput()));
    static StreamWriter sw = new StreamWriter(new BufferedStream(Console.OpenStandardOutput()));
    static void Main()
    {
        int n = ReadInt();
        int[] renList = new int[200];

        for (int i = 0; i < n; i++)
        {
            renList[ReadInt() % 200]++;
        }

        long res = 0;
        foreach (int item in renList)
        {
            if (item > 1)
            {
                res += (long)item * (item - 1) / 2;
            }
        }

        sw.WriteLine($"{res}");
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