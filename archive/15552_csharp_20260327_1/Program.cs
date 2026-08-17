using System;
using System.IO;

class Program
{
    static byte[] buf = new byte[1 << 16];
    static int bufPos = 0, bufLen = 0;
    static Stream stdin = Console.OpenStandardInput();
    static StreamWriter sw = new StreamWriter(new BufferedStream(Console.OpenStandardOutput()));

    static void Main()
    {
        int n = ReadInt();
        for (int i = 0; i < n; i++)
        {
            sw.WriteLine($"{ReadInt() + ReadInt()}");
        }

        sw.Flush();
    }

    static int Read()
    {
        if (bufPos >= bufLen)
        {
            bufLen = stdin.Read(buf, 0, buf.Length);
            bufPos = 0;
        }
        return bufLen == 0 ? -1 : buf[bufPos++];
    }

    static int ReadInt()
    {
        int c;
        bool neg = false;

        while ((c = Read()) < '0' || c > '9')
            if (c == '-') neg = true;

        int r = c - '0';
        while ((c = Read()) >= '0' && c <= '9')
            r = r * 10 + (c - '0');

        return neg ? -r : r;
    }
}
