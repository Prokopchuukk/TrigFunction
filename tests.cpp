#include "FuncClass.h"
#include <cassert>
#include <cmath>
#include <iostream>

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


int main() {
    std::cout << "Running tests...\n";

    TestSmallValues();
    std::cout << "TestSmallValues passed.\n";

    TestLargeValues();
    std::cout << "TestLargeValues passed.\n";

    std::cout << "All tests passed!\n";
    return 0;
}