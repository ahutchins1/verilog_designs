import numpy as np
from scipy.signal import iirfilter, freqz, lfilter
from scipy.fftpack import fft
import matplotlib.pyplot as plt
from tool._fixedInt import *

def iir_filter(x,b,a,y):
    xn_coeff = np.zeros(len(x))
    yn_coeff = np.zeros(len(y))
    for i in range(len(x)):
        xn_coeff[i] = x[i] * b[i]
    for i in range(len(y)):
        yn_coeff[i] = y[i] * a[i]
    fp_acumulador = xn_coeff[0]
    for index in range(1,len(xn_coeff)):fp_acumulador = fp_acumulador + xn_coeff[index]
    for index in range(len(yn_coeff)):fp_acumulador = fp_acumulador - yn_coeff[index]
    return fp_acumulador

def quantz(NB,NBF,x):
    y_aux = arrayFixedInt(NB,NBF,x)
    y = [a.fValue for a in y_aux]
    return y

def quantzh(NB,NBF,x):
    y_aux = arrayFixedInt(NB,NBF,x)
    y = [a.__hex__() for a in y_aux]
    return y


def iir_filter_Q(signal_in,sample_rate, nsamples):

    # sample_rate = 48000
    # nsamples = 1024
    nyq_rate = sample_rate / 2
    f_cutoff = 6000
    order = 2                   # (corresponde a 3 coeficientes b y 2 a)
    NB = 16
    NBF = 15

    b, a = iirfilter(order, f_cutoff/nyq_rate, btype='low', ftype='butter')
    numtaps = len(b)
    init_coeff = np.ones(numtaps)
    init_coeff_y = np.ones(numtaps - 1)
    b_coeff = quantz(NB,NBF,b)
    a_coeff = quantz(NB,NBF,a[1:])
    xn = quantz(NB,NBF,init_coeff)
    yn = quantz(NB,NBF,init_coeff_y)
    fp_filtered = []
    temp = [0.0]*numtaps
    temp_y = [0.0]*(numtaps - 1)
    
    for value in signal_in: 
        temp.insert(0,value)
        temp.pop()
        for j in range(numtaps): xn[j] = temp[j]
        for j in range(numtaps - 1): yn[j] = temp_y[j]
        Yn = iir_filter(xn,b_coeff,a_coeff,yn)
        temp_y.insert(0,Yn)
        temp_y.pop()
        fp_filtered.append(Yn) 
    
    output_f = quantz(NB,NBF,fp_filtered)
    return output_f, b_coeff,[value.fValue for value in arrayFixedInt(NB,NBF,a)]

F_Sample  = 48000 
N_Samples = 1024
F_Main    = 1500
F_Noise   = 36000
A_Main    = 1.0
A_Noise   = 0.5

t = np.arange(N_Samples) / F_Sample
NFFT = 1024
xfft = np.linspace(0.0, 1.0/(2.0*t[1]), NFFT//2)

noise        = A_Noise * np.sin(2*np.pi*F_Noise*t)
clean_signal = A_Main  * np.sin(2*np.pi*F_Main*t)
gen_signal = clean_signal + noise

[filtered_signal, b, a] = iir_filter_Q(gen_signal,F_Sample, N_Samples)

# Plot de la respuesta en frecuencia
w, h = freqz(b, a)
plt.figure(1)
plt.plot(w / np.pi, 20 * np.log10(abs(h)))
plt.title('Respuesta en Frecuencia - Filtro Diseñado')
plt.xlabel('Frecuencia Normalizada (xπ rad/muestra)')
plt.ylabel('Magnitud (dB)')
plt.grid()
plt.show()

#Plot temporal
plt.figure(2)
plt.title('IIR Filter')
plt.plot(gen_signal[800:], label='Noisy signal')
plt.plot(filtered_signal[800:], label='FP Filtered Signal')
plt.legend()
plt.grid(True)
plt.show()

fft_gen_signal = fft(gen_signal,NFFT)
fft_filtered_signal = fft(filtered_signal,NFFT)

# FFT PLOT
plt.figure(3)
plt.title('FFT (%d taps)' % NFFT)
plt.plot(xfft,2.0/NFFT * np.abs(fft_gen_signal[0:NFFT//2]),'r-', label='Noisy Signal')
plt.plot(xfft,2.0/NFFT * np.abs(fft_filtered_signal[0:NFFT//2]),'b' ,linewidth=2, label='Filtered Signal')
plt.legend()
plt.grid(True)
plt.show()

#Coeficientes en consola
print("Coeficientes b:", b)
print("Coeficientes a:", a)

print("Coeficientes b:", quantzh(16,15,b))
print("Coeficientes a:", quantzh(16,15,a))
