# ���������� � �����
CC = g++
ASM = nasm
CFLAGS = -Wall -Wextra -std=c++17
ASMFLAGS = -f elf64
LDFLAGS = 

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