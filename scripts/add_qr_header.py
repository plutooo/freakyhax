#!/usr/bin/python3

import sys
import struct
import hashlib
import hmac

buf = open(sys.argv[1], "rb").read()

alloc_len = 0x1B0
buf_len = len(buf)

f = open(sys.argv[2], "wb")

f.write(b"3DCT")
f.write(struct.pack("HH", alloc_len, buf_len))

h = hmac.new(bytearray('PICTOYNINTENDOAS', 'utf-8'), digestmod=hashlib.sha1)
h.update(buf)

f.write(h.digest())
f.write(struct.pack("I", 0))

f.write(buf)
