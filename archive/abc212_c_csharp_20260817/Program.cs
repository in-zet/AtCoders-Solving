using System;
using System.IO;
using System.Linq;

class Program
{
    static StreamReader sr = new StreamReader(new BufferedStream(Console.OpenStandardInput()));
    static StreamWriter sw = new StreamWriter(new BufferedStream(Console.OpenStandardOutput()));
    static void Main()
    {
        int numA = ReadInt();
        int numB = ReadInt();

        int[] aArr = new int[numA];
        int[] bArr = new int[numB];

        for (int i = 0; i < numA; i++)
        {
            aArr[i] = ReadInt();
        }
        for (int i = 0; i < numB; i++)
        {
            bArr[i] = ReadInt();
        }

        if (numA > numB)
        {
            int[] cArr = aArr;
            aArr = bArr;
            bArr = cArr;
        }

        Array.Sort(aArr);
        Array.Sort(bArr);

        int res = Math.Abs(aArr[0] - bArr[0]);

        foreach (int value in aArr)
        {
            int index = bSearch(bArr, value, 0, bArr.Length - 1);
            int bSNum = index == 0 ? Math.Abs(value - bArr[0]) : Math.Min(Math.Abs(value - bArr[index]), Math.Abs(value - bArr[index - 1]));
            res = Math.Min(res, bSNum);
        }

        sw.WriteLine($"{res}");
        sw.Flush();
        return;
    }

    static int bSearch(int[] arr, int target, int start, int end)
    {
        if (end - start <= 1)
        {
            return end;
        }

        int midI = (int)((start + end) / 2.0);
        int mid = arr[midI];
        if (target > mid)
        {
            return bSearch(arr, target, midI, end);
        }
        return bSearch(arr, target, start, midI);
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