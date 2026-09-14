#include <stdio.h>
#include "util.h"

void greet(const char *name)
{
    printf("Hello, %s! Welcome to Mini Dev-C++.\n", name);
}

int sum_to(int n)
{
    int total = 0;
    int i;

    for (i = 1; i <= n; i++) {
        total += i;
    }
    return total;
}
