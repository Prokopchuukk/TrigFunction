#include "FuncClass.h"
#include <cmath>

double FuncClass::FuncA(int n) {
    double result = 0.0;
    for (int i = 0; i < n; ++i) {
        double term = (std::tgamma(2 * i + 1) / 
                      (std::pow(4, i) * std::pow(std::tgamma(i + 1), 2) * (2 * i + 1)));
        result += term;
    }
    return result;
}