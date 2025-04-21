# Compressed Multiplier with:
# 1. Carry Save Adder Reduction
# 2. Wallace Tree Reduction
# Author : Hutchins Andres

# Multiplication to perform:  10_1101 * 11_1011

# 2. Wallace tree

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

Cout = [[0,0,0,0,0,0],
        [0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0]]
s    = [[0,0,0,0,0,0],
        [0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0]]
p    = [pp[0][0],0,0]

fa_count = 0

#Level 0 first group
s[0][0],Cout[0][0] = half_adder(pp[0][1],pp[1][0])
for j in range(1,5):
    s[0][j],Cout[0][j] = full_adder(pp[2][j-1],pp[1][j],pp[0][j+1])  
    fa_count+=1

s[0][5],Cout[0][5] = half_adder(pp[2][4],pp[1][5])
p[1] = s[0][0]

#Level 0 second group
s[1][0],Cout[1][0] = half_adder(pp[3][1],pp[4][0])
for j in range(1,5):
    s[1][j],Cout[1][j] = full_adder(pp[5][j-1],pp[4][j],pp[3][j+1])  
    fa_count+=1

s[1][5],Cout[1][5] = half_adder(pp[5][4],pp[4][5])

print ("Level 0 / 1")
print ("1st group S  " + str(s[0][::-1]))
print ("1st group Co " + str(Cout[0][::-1]))
print ("2nd group S  " + str(s[1][::-1]))
print ("2nd group Co " + str(Cout[1][::-1]))

#Level 2
s[0][0],Cout[0][0] = half_adder(s[0][1],Cout[0][0])
s[0][1],Cout[0][1] = full_adder(pp[3][0],s[0][2],Cout[0][1])
s[0][2],Cout[0][2] = full_adder(s[0][3],s[1][0],Cout[0][2])
s[0][3],Cout[0][3] = full_adder(s[0][4],s[1][1],Cout[0][3])
s[0][4],Cout[0][4] = full_adder(s[0][5],s[1][2],Cout[0][4])
s[0][5],Cout[0][5] = full_adder(pp[2][5],s[1][3],Cout[0][5])
fa_count+=5
p[2] = s[0][0]

print ("Level 2")
print ("S  " + str(s[0][::-1]))
print ("Co " + str(Cout[0][::-1]))

#Level 3 
s[2][0],Cout[2][0] = half_adder(s[0][1],            Cout[0][0])
s[2][1],Cout[2][1] = half_adder(s[0][2],            Cout[0][1])
s[2][2],Cout[2][2] = full_adder(s[0][3], Cout[1][0],Cout[0][2])
s[2][3],Cout[2][3] = full_adder(s[0][4], Cout[1][1],Cout[0][3])
s[2][4],Cout[2][4] = full_adder(s[0][5], Cout[1][2],Cout[0][4])
s[2][5],Cout[2][5] = full_adder(s[1][4], Cout[1][3],Cout[0][5])
s[2][6],Cout[2][6] = half_adder(s[1][5], Cout[1][4])
s[2][7],Cout[2][7] = half_adder(pp[5][5],Cout[1][5])
fa_count+=4

print ("Level 3")
print ("S  " + str(s[2][::-1]))
print ("Co " + str(Cout[2][::-1]))
print ("P  " + str(p[::-1]))

#CPA

Vector_A = p + s[2][:]

Cout_shifted = [0] + Cout[2][:7]

Cout_padded = [0] * (len(Vector_A) - len(Cout_shifted)) + Cout_shifted 

final_sum, final_carry = ripple_carry_adder(Vector_A, Cout_padded, Cin=0)

print ("Final Result     " + str(final_sum[::-1]))

print ("Final Result exp " + str([1,0,1,0,0,1,0,1,1,1,1,1]))

print ("Full Adders used: " + str(fa_count))
