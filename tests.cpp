#include "FuncClass.h"
#include <cassert>
#include <cmath>
#include <iostream>
#include <chrono>
#include <vector>
#include <random>

void TestSmallValues() {
    FuncClass funcClass;

    // Test for n = 0
    assert(std::abs(funcClass.FuncA(0) - 0.0) < 1e-9);

    // Test for n = 1
    assert(std::abs(funcClass.FuncA(1) - 1.0) < 1e-9);

    // Test for n = 2
    double expected_n2 = 1.0 + (1.0 / 6.0);
    assert(std::abs(funcClass.FuncA(2) - expected_n2) < 1e-9);
}

void TestLargeValues() {
    FuncClass funcClass;

    // Test for n = 10
    double result_n10 = funcClass.FuncA(10);
    assert(result_n10 > 0.0); // The result should be greater than zero, adjust the check for broader range.
    // Adjusted upper bound based on expected results for FuncA(10)
    assert(result_n10 < 5.0); // This is an example bound; adjust if necessary based on the expected result
}

// New test for calculating execution time
void TestCalculationTime() {
    FuncClass funcClass;

    // Record the start time
    auto t1 = std::chrono::high_resolution_clock::now();

    std::vector<double> aValues;
    std::random_device rd;
    std::mt19937 mtre(rd());
    std::uniform_real_distribution<double> distr(0.0, 2 * M_PI);

    // Generate 2,000,000 random values and calculate their trigonometric function
    for (int i = 0; i < 2000000; i++) {
        double randomValue = distr(mtre);
        double calculatedValue = funcClass.FuncA(30);
        aValues.push_back(calculatedValue);
    }

    // Record the end time
    auto t2 = std::chrono::high_resolution_clock::now();
    
    // Calculate the duration
    auto int_ms = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);
    int iMS = int_ms.count();

    // Check if the calculation time is within 5 to 20 seconds
    assert(iMS >= 5000 && iMS <= 20000);

    // Print out the result for verification
    std::cout << "Calculation time: " << iMS << " milliseconds\n";
}

int main() {
    std::cout << "Running tests...\n";

    TestSmallValues();
    std::cout << "TestSmallValues passed.\n";

    TestLargeValues();
    std::cout << "TestLargeValues passed.\n";

    TestCalculationTime();
    std::cout << "TestCalculationTime passed.\n";

    std::cout << "All tests passed!\n";
    return 0;
}

