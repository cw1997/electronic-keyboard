#include <stdio.h>
#include <math.h>

/**
 * 1 / ( ln(2) * capacitance * (resistance_1 + 2 * resistance_2 ) ) = frequency_value
 * resistance_1 = 1 / frequency_value / ln(2) / capacitance - 2 * resistance_2
 * @param capacitance
 * @param resistance_2
 */
void calculate(const double capacitance, const double resistance_2) {
    const int key_count = 88;
    double frequencies[key_count];
    for (int i = 0; i < key_count; ++i) {
        int key_index = i + 1;
        double frequency = pow(2, (double)key_index / 12) * 27.500;
        frequencies[i] = frequency;
    }
//    double frequencies[7*2] = {
//            261.626,
//            293.665,
//            329.629,
//            349.228,
//            391.995,
//            440.000,
//            446.164,
//            (261.626 * 2),
//            (293.665 * 2),
//            (329.629 * 2),
//            (349.228 * 2),
//            (391.995 * 2),
//            (440.000 * 2),
//            (446.164 * 2),
//    };
    double resistance_values[key_count];
    for (int frequency_index = key_count - 1; frequency_index >= 0; --frequency_index) {
        const double frequency = frequencies[frequency_index];
        resistance_values[frequency_index] = 1 / frequency / log(2) / capacitance - 2 * resistance_2;
//        if (frequency_index < 6) {
//            for (int j = frequency_index + 1; j < 7; ++j) {
//                resistance_values[frequency_index] = resistance_values[frequency_index] - resistance_values[j];
//            }
//        }
    }
    for (int i = 0; i < key_count; ++i) {
        printf("key_index: %2d, frequency [%8.3lf(Hz)]: %10.3lf(Ohm)\n", i + 1, frequencies[i], resistance_values[i]);
        if ((i + 1) % 12 == 0) printf("%d\n", (i + 1) / 12 + 1);
    }
}

int main() {
    const double capacitance = 0.0000001;
    const double resistance_2 = 100;
    calculate(capacitance, resistance_2);
}
