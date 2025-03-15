#include <stdio.h>

extern "C" void MyPrintf(const char* str, ...);

int main()
{
    MyPrintf("PARASHA %c %c %d!!\n!!", 'h', 'g', 123);
    // MyPrintf("PARASHA!!!");

    return 0; 
}       