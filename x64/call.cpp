//********************
//
// Introduction to x64 Assembly
// http://software.intel.com/en-us/articles/introduction-to-x64-assembly
//
// 在配置管理器中添加并使用 x64
//
// 添加的新项目其默认的解决方案平台是 Win32，不要删除这个 Win32 平台。否则解决方案中只有 x64 的时候再添加
// 新项目，该项目仍然默认为 Win32 平台，但没办法设置为 x64，尽管此时解决方案中只有一个 x64。可能是 bug。
// 这时只能添加 Win32，删除 x64，添加 x64，然后新项目的平台才会和其他项目一同变成 x64。


// C++ code to demonstrate x64 assembly file linking
#include <iostream>

// double __cdecl CombineC(int,int,int,int,int,double)
double CombineC(int a, int b, int c, int d, int e, double f) {
    return (a + b + c + d + e) / (f + 1.5);
}

// NOTE: extern "C" needed to prevent C++ name mangling
extern "C" double CombineA(int a, int b, int c, int d, int e, double f);

int main() {
    std::cout << "CombineC: " << CombineC(1, 2, 3, 4, 5, 6.1) << std::endl;
    std::cout << "CombineA: " << CombineA(1, 2, 3, 4, 5, 6.1) << std::endl;
}

/********************/