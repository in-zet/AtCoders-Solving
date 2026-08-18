using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

class MyMinQ
{
    private PriorityQueue<long, long> pq = new PriorityQueue<long, long>();
    private long addiction = 0;

    public void Operate(int operType, int operN = 0)
    {
        switch (operType)
        {
            case 1:
                long temp = operN - addiction;
                pq.Enqueue(temp, temp);
                break;
            case 2:
                addiction += operN;
                break;
            case 3:
                Program.sw.WriteLine(pq.Dequeue() + addiction);
                break;
            default:
                break;
        }
    }
}

class Program
{
    static Stream inStream = Console.OpenStandardInput();
    static byte[] buffer = new byte[1 << 16];
    static int bufferLen = 0, bufferPtr = 0;

    static public StreamWriter sw = new StreamWriter(new BufferedStream(Console.OpenStandardOutput())) { NewLine = "\n" };

    static void Main()
    {
        int operNum = ReadInt();
        MyMinQ queue = new MyMinQ();

        for (int i = 0; i < operNum; i++)
        {
            int type = ReadInt();
            if (type != 3)
            {
                queue.Operate(type, ReadInt());
            }
            else
            {
                queue.Operate(type);
            }
        }

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

    static long ReadLong()
    {
        int c;
        long r = 0;
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

    static string ReadToken()
    {
        int c;
        do { c = ReadByte(); } while (c == ' ' || c == '\n' || c == '\r');

        var sb = new System.Text.StringBuilder();
        while (c != -1 && c != ' ' && c != '\n' && c != '\r')
        {
            sb.Append((char)c);
            c = ReadByte();
        }
        return sb.ToString();
    }
}
