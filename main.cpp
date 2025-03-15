#include <stdio.h>

extern "C" void MyPrintf(const char* str, ...);

int main()
{
    MyPrintf("PARASHA %c %c %d %b !!\n %s!!", 'h', 'g', 123, 555, "stroka");

    return 0; 
}       