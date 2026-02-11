import sys

bin_path=sys.argv[1]
hex_path=sys.argv[2]

data=open(bin_path,"rb").read()

if len(data)%4!=0:
    data+=b"\x00"*(4-(len(data)%4))

with open(hex_path,"w") as f:
    for i in range(0,len(data),4):
        b0,b1,b2,b3=data[i:i+4]
        word=(b3<<24)|(b2<<16)|(b1<<8)|(b0)
        f.write("{:08x}\n".format(word))
