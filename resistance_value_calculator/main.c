#include <stdio.h>

/**
 * 1.44/((R+2*resistance_2)*capacitance) = frequency_value
 * @param capacitance
 * @param resistance_2
 */
const double ln2 = 1.44;
void calculate(const double capacitance, const double resistance_2) {
    double frequencies[7] = {
            261.626,
            293.665,
            329.629,
            349.228,
            391.995,
            440.000,
            446.164,
    };
    double resistance_values[7];
    for (int frequency_index = 6; frequency_index >= 0; --frequency_index) {
        const double frequency = frequencies[frequency_index];
        resistance_values[frequency_index] = (ln2 / frequency) / capacitance - 2 * resistance_2;
//        if (frequency_index < 6) {
//            for (int j = frequency_index + 1; j < 7; ++j) {
//                resistance_values[frequency_index] = resistance_values[frequency_index] - resistance_values[j];
//            }
//        }
    }
    for (int i = 0; i < 7; ++i) {
        printf("frequency [%6.3lf(Hz)]: %9.3lf(Ohm)\n", frequencies[i], resistance_values[i]);
    }
}

int main() {
    const double capacitance = 0.0000001;
    const double resistance_2 = 10000;
    calculate(capacitance, resistance_2);
}
