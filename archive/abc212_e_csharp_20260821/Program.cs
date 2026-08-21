using System;
using System.IO;
using System.Collections.Generic;

class Program
{
    static Stream inStream = Console.OpenStandardInput();
    static byte[] buffer = new byte[1 << 16];
    static int bufferLen = 0, bufferPtr = 0;

    static StreamWriter sw = new StreamWriter(new BufferedStream(Console.OpenStandardOutput())) { NewLine = "\n" };

    static void Main()
    {
        int DV = 998244353;

        int n = ReadInt();  // # of cities
        int m = ReadInt();  // # of unusable road
        int k = ReadInt();  // # of days
        List<int>[] uRoad = new List<int>[n];  // [to][from]
        for (int i = 0; i < n; i++)
        {
            uRoad[i] = new List<int>();
            uRoad[i].Add(i);
        }

        for (int i = 0; i < m; i++)
        {
            int temp = ReadInt() - 1;
            int temp2 = ReadInt() - 1;
            uRoad[temp2].Add(temp);
            uRoad[temp].Add(temp2);
        }

        int[][] dp = new int[k][];  // [day][city]
        int[] allPath = new int[k];  // [day]

        dp[0] = new int[n];  // 암묵적으로 0으로 초기화
        dp[0][0] = 1;
        allPath[0] = 1;

        for (int day = 1; day < k; day++)
        {
            dp[day] = new int[n];
            for (int city = 0; city < n; city++)
            {
                long temp = allPath[day - 1];
                foreach (int uCity in uRoad[city])
                {
                    temp -= dp[day - 1][uCity];
                }
                while (temp < 0)
                {
                    temp += DV;
                }
                dp[day][city] = (int)temp;
                allPath[day] = (int)(((long)allPath[day] + temp) % DV);
            }
        }

        long res = allPath[k - 1];
        foreach (int uCity in uRoad[0])
        {
            res -= dp[k - 1][uCity];
        }

        while (res < 0)
        {
            res += DV;
        }

        sw.WriteLine(res);
        sw.Flush();
    }

    static int ReadByte()
    {
        if (bufferPtr == bufferLen)
        {
            bufferLen = inStream.Read(buffer, 0, buffer.Length);
            bufferPtr = 0;
            if (bufferLen <= 0) return -1;
        }
        return buffer[bufferPtr++];
    }

    static int ReadInt()
    {
        int c, r = 0;
        bool neg = false;

        do { c = ReadByte(); } while (c != '-' && (c < '0' || c > '9'));
        if (c == '-') { neg = true; c = ReadByte(); }

        while (c >= '0' && c <= '9')
        {
            r = r * 10 + (c - '0');
            c = ReadByte();
        }

        return neg ? -r : r;
    }
}
