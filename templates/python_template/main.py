import os, io, sys
input = io.BytesIO(os.read(0, os.fstat(0).st_size)).readline

ints = list(map(int, input().split()))

sys.stdout.write("Hello, World!")