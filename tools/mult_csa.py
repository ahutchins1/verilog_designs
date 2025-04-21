# Compressed Multiplier with:
# 1. Carry Save Adder Reduction
# 2. Wallace Tree Reduction
# Author : Hutchins Andres

# Multiplication to perform:  10_1101 * 11_1011

# 1. Carry Save Adder

def half_adder(a, b):
    sum_bit = a ^ b  
    carry_bit = a & b  
    return sum_bit, carry_bit

def full_adder(a, b, carry_in):
    sum_bit = a ^ b ^ carry_in
    carry_out = (a & b) | (b & carry_in) | (a & carry_in)
    return sum_bit, carry_out

def ripple_carry_adder(A, B, Cin):
    sum_bits = []
    carry = Cin  
    for i in range(len(A)):
        a_bit = A[i]
        b_bit = B[i]
        sum_bit, carry = full_adder(a_bit, b_bit, carry)
        sum_bits.append(sum_bit)
    sum_bits.append(carry)
    return sum_bits, carry

pp = [
    [1, 0, 1, 1, 0, 1],
    [1, 0, 1, 1, 0, 1],
    [0, 0, 0, 0, 0, 0],
    [1, 0, 1, 1, 0, 1],
    [1, 0, 1, 1, 0, 1],
    [1, 0, 1, 1, 0, 1],
]
 
a    = [pp[1][0], pp[2][0], pp[2][1], pp[2][2], pp[2][3], pp[2][4]]
b    = [pp[0][1], pp[1][1], pp[1][2], pp[1][3], pp[1][4], pp[1][5]]
Cin  = [pp[0][2], pp[0][3], pp[0][4], pp[0][5]]
Cout = [0,0,0,0,0,0]
s    = [0,0,0,0,0,0]
p    = [pp[0][0],0,0,0,0]

fa_count = 0

for i in range(0,4):
    if (i == 0):

        s[0],Cout[0] = half_adder(a[0],b[0])

        for j in range(1,5):
            s[j],Cout[j] = full_adder(a[j],b[j],Cin[j-1])
            fa_count+=1

        s[5],Cout[5] = half_adder(a[5],b[5])
        p[i+1] = s[0]

    else:
        s[0],Cout[0] = half_adder(s[1],Cout[0])

        for j in range(1,5):
            s[j],Cout[j] = full_adder(pp[i+2][j-1],s[j+1],Cout[j])
            fa_count+=1
        s[5],Cout[5] = full_adder(pp[i+2][4],pp[i+1][5],Cout[5])
        fa_count+=1
        p[i+1] = s[0]

    print ("Level " + str(i))
    print ("S  " + str(s[::-1]))
    print ("Co " + str(Cout[::-1]))

s[0] = s[1]
s[1] = s[2]
s[2] = s[3]
s[3] = s[4]
s[4] = s[5]
s[5] = pp[5][5]

print ("Level 3" )
print ("S  " + str(s[::-1]))
print ("Co " + str(Cout[::-1]))
print ("P  " + str(p[::-1]))

#CPA

Vector_A = p + s

Cout_shifted = [0] + Cout[:]

Cout_padded = [0] * (len(Vector_A) - len(Cout_shifted)) + Cout_shifted 

final_sum, final_carry = ripple_carry_adder(Vector_A, Cout_padded, Cin=0)

print ("Final Result     " + str(final_sum[::-1]))

print ("Final Result exp " + str([1,0,1,0,0,1,0,1,1,1,1,1]))

print ("Full Adders used: " + str(fa_count))

print(Vector_A[::-1])

print(Cout_padded[::-1])

