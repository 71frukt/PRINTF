#include <stdio.h>
#include <math.h>

extern "C" void MyPrintf(const char* str, ...);

int main()
{
    // MyPrintf("PARASHA %s '%f' %b %o |%h| '%%'\n", "str", 123.456, 12, 777, 123);
    
    // MyPrintf("parasha %d %d %d %d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    MyPrintf("%f \n%f \n%d \n%f \n%f \n%f \n%f \n%d \n%f \n%f \n%f \n%d %d %d \n%f\n %d %d %d\n %f\n", 1.2, 2.3, 345, 4.5, 5.6, 6.7, 7.8, 123, 8.9, 9.1, -10.2, 789, 789, 789, 1.0123, 12, 11, 13, 1e-8);

    MyPrintf("%f\n", -INFINITY);

    printf("%f\n", 1e-8);

    return 0; 
}       