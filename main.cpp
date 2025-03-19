#include <stdio.h>
#include <math.h>

extern "C" void MyPrintf(const char *const str, ...);

int main()
{
    // MyPrintf("Этот принтф %s %b %o |%h| '%%'\n", "str", 12, 777, 123);

    // MyPrintf("%f %f %f\n", 1.23, 4.56, 7.89);
    
    // MyPrintf("parasha %d %d %o %d %d %o %d %d %o %d\n", 1, 2, 30, 4, 5, 6, 7, 8, 9, 10);

    // MyPrintf(" %f \n%f \n%x \n%f \n%f \n%f \n%f \n%h \n%f \n%f \n%f \n%d %d %d \n%f\n %d %d %d\n %f\n", 1.2, 2.3, 345, 4.5, 5.6, 6.7, 7.8, 123, 8.9, 9.1, -10.2, 789, 789, 789, 1.0123, 12, 11, 13, 1e-8);

    // MyPrintf("%f\n", -INFINITY);

    // printf("%f\n", 1e-8);

    MyPrintf("Этот принтф \n%s %s \nи их число больше %d и %d\n"                                 
             "вот например число %c: \t\t%f\n" 
             "число -P:\t\t\t%f\n"
             "%s если хотите:    \t%f\n"
             "и %cбесконечность: \t\t%f\n"
             "можно %s: \t\t\t%f\n"
             "оч маленькое 1e-%d \t\t%f\n"
             "и оч большое 1e%d\t\t%f\n"
             "ещё чисел %f %d %f %d\n"
             "hex %x, oct %o, bin %b\n"
             "может хватит с него уже\n\n\n",
        "получил самые разнообразные", "целочисленные и дробные аргументы", 5, 8, 'P',
        M_PI, -M_PI, "бесконечность", INFINITY, '-', -INFINITY, "nan", NAN, 6, 1e-6, 8, 1e8, 1.23, -777, 4.56, 888,
        123, 456, 789);

    return 0; 
}       