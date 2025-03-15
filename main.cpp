#include <stdio.h>

extern "C" void MyPrintf(const char* str, ...);

int main()
{
    MyPrintf("PARASHA %c %c %c!!\n!!", 'h', 'g', 'b');

    return 0; 
} 