import numpy
from pylab import *
# from tool._fixedInt import *

def gen_signal_csv(signal, output_file):
    with open(output_file, 'w') as f:
        for value in signal:
            f.write(str(value) + '\n')

def sdec2bin(n):
    # Asegurarse de que el número esté dentro del rango válido para 16 bits (-32768 a +32767)
    if n < -32768 or n > 32767:
        raise ValueError("El número está fuera del rango de representación de 16 bits.")

    # Para números negativos, calcular el complemento a dos de forma explícita
    if n < 0:
        # Invertir los bits y sumar 1 para obtener complemento a dos
        n = ~(-n) & 0xFFFF  # Inversión de bits (NOT) y AND con 0xFFFF para limitar a 16 bits
        n += 1  # Sumar 1 para obtener complemento a dos

    # Convertir a binario y rellenar con ceros para que tenga 16 bits
    binary_representation = f"{n:016b}"

    return binary_representation


NBF_In    = 15    #Number of fractional bits in the quantized input
F_Sample  = 48000 
N_Samples = 1024
F_Main    = 1500
F_Noise   = 17000
A_Main    = 1.0
A_Noise   = 0.5

t = numpy.arange(N_Samples) / F_Sample

noise        = A_Noise * numpy.sin(2*numpy.pi*F_Noise*t)
clean_signal = A_Main  * numpy.sin(2*numpy.pi*F_Main*t)
gen_signal = clean_signal + noise
adapted_signal = gen_signal * 2**NBF_In / (A_Main + A_Noise)

#Signed Input assumption
noisy_signal_b = [] 
noisy_signal_f = [] 
for value in adapted_signal:
    if value > 2**NBF_In:
        corrected_value = 2**NBF_In - 1
    else:
        corrected_value = value
    corrected_value_b = sdec2bin(int(corrected_value))
    noisy_signal_f.append(corrected_value)
    noisy_signal_b.append(corrected_value_b)


plt.figure(figsize=(8, 6), dpi=200)
plt.plot(t[0:100], noisy_signal_f[0:100], label='noisy signal')
plt.legend()
plt.xlabel('Time (s)')
plt.ylabel('Amplitude')
plt.title('Noisy Signal')
plt.grid(True)
plt.show()

gen_signal_csv(noisy_signal_b,"tb_i_noisy_sin.txt")