# Distributed Arithmetic ROM based FIR Filter
# Coeffs: h = [-0.0456 -0.1703 0.0696 0.3094 0.4521 0.3094 0.0696 -0.1703 -0.0456]
# Coeffs format S(16.15)
# Input format S(8.7)

from tool._fixedInt import *

# For a standard FIR filter

N_COEFFS   = 9
N_ADDR_ROM = 2**N_COEFFS

h = [-0.0456, -0.1703, 0.0696, 0.3094, 0.4521, 0.3094, 0.0696, -0.1703, -0.0456]
h  = [value for value in h]

rom_data = [0 for _ in range(0,N_ADDR_ROM)]
for i in range(0,N_ADDR_ROM):
    rom_data[i] = 0
    for j in range(0,N_COEFFS):
        if (i >> j) & 1:
            rom_data[i] = rom_data[i] + h[j]
rom_data = [value for value in rom_data]

# quant_rom_value = arrayFixedInt(20,15,rom_data) #careful with the size //20,15
# hex_rom_value = [value.__hex__() for value in quant_rom_value]

# with open("rom_hex.mem", 'w') as f:
#     for value in hex_rom_value:
#         f.write(str(value) + '\n')

#-------------------------------------------------------------

# For a symmetrical FIR filter: 4 groups of 2 coeffs, 3 possible values (0, 1 or 2) + the central coeff
new_rom_data = []
value_to_indices = {}
remap_addr = [0 for _ in range(0,N_ADDR_ROM)]
d = 0 #Unique values counter

for idx, value in enumerate(rom_data):
    if value in value_to_indices:
        value_to_indices[value].append(idx)
        remap_addr[idx] = remap_addr[value_to_indices[value][0]] # Generate remapping table
    else:
        value_to_indices[value] = [idx]
        remap_addr[idx] = d                                      # Generate remapping table
        d = d+1
        new_rom_data.append(rom_data[idx])
new_rom_data = [value for value in new_rom_data]

quant_remap = arrayFixedInt(12,0,remap_addr) #careful with the size //20,15
hex_remap = [value.__hex__() for value in quant_remap]

with open("remap.mem", 'w') as f:
    for value in hex_remap:
        f.write(str(value) + '\n')

quant_rom_value = arrayFixedInt(20,15,new_rom_data) #careful with the size //20,15
hex_rom_value = [value.__hex__() for value in quant_rom_value]

with open("symm_rom_hex.mem", 'w') as f:
    for value in hex_rom_value:
        f.write(str(value) + '\n')




