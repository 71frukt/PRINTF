# ���������� � �����
CC = g++
ASM = nasm
CFLAGS = -Wall -Wextra -std=c++17
ASMFLAGS = -f elf64
LDFLAGS = -no-pie -Wshadow -Winit-self -Wredundant-decls -Wcast-align -Wundef -Wfloat-equal -Winline -Wunreachable-code -Wmissing-declarations -Wmissing-include-dirs \
		-Wswitch-enum -Wswitch-default -Weffc++ -Wmain -Wextra -Wall -g -pipe -fexceptions -Wcast-qual -Wconversion -Wctor-dtor-privacy -Wempty-body -Wformat-security \
		-Wformat=2 -Wignored-qualifiers -Wlogical-op -Wno-missing-field-initializers -Wnon-virtual-dtor -Woverloaded-virtual -Wpointer-arith -Wsign-promo \
		-Wstrict-aliasing -Wstrict-null-sentinel -Wtype-limits -Wwrite-strings -Werror=vla -D_DEBUG -D_EJUDGE_CLIENT_SIDE -std=c++11

# �������� �����
SRC_ASM = my_printf.asm
SRC_CPP = main.cpp

# ��������� �����
OBJ_ASM = my_printf.o
OBJ_CPP = main.o

# �������� ����������� ����
TARGET = prog

# ������� �� ���������
all: $(TARGET)

# ������ ������������ �����
$(TARGET): $(OBJ_CPP) $(OBJ_ASM)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJ_CPP) $(OBJ_ASM)

# ���������� C++ �����
$(OBJ_CPP): $(SRC_CPP)
	$(CC) $(CFLAGS) -c $(SRC_CPP) -o $(OBJ_CPP)

# ��������������� ������������� �����
$(OBJ_ASM): $(SRC_ASM)
	$(ASM) $(ASMFLAGS) $(SRC_ASM) -o $(OBJ_ASM)

# �������
clean:
	rm -f $(OBJ_CPP) $(OBJ_ASM) $(TARGET)

# ����������
rebuild: clean all