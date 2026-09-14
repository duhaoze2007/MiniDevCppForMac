/*
 * Demo project for Mini Dev-C++ — two translation units, a header, keyboard
 * input and a function call into a second file, i.e. the classic Dev-C++ first
 * project.
 */

#include <stdio.h>
#include "util.h"

int main(void)
{
    char name[64];

    printf("What is your name? ");
    fflush(stdout);
    if (scanf("%63s", name) != 1) {
        return 1;
    }

    greet(name);
    printf("1 + 2 + ... + 10 = %d\n", sum_to(10));
    printf("Bye!\n");
    return 0;
}
