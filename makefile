# Компилятор и флаги
CC = g++
ASM = nasm
CFLAGS = -Wall -Wextra -std=c++17
ASMFLAGS = -f elf64
LDFLAGS = 

# Исходные файлы
SRC_ASM = my_printf.asm
SRC_CPP = main.cpp

# Объектные файлы
OBJ_ASM = my_printf.o
OBJ_CPP = main.o

# Итоговый исполняемый файл
TARGET = prog

# Правило по умолчанию
all: $(TARGET)

# Сборка исполняемого файла
$(TARGET): $(OBJ_CPP) $(OBJ_ASM)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJ_CPP) $(OBJ_ASM)

# Компиляция C++ файла
$(OBJ_CPP): $(SRC_CPP)
	$(CC) $(CFLAGS) -c $(SRC_CPP) -o $(OBJ_CPP)

# Ассемблирование ассемблерного файла
$(OBJ_ASM): $(SRC_ASM)
	$(ASM) $(ASMFLAGS) $(SRC_ASM) -o $(OBJ_ASM)

# Очистка
clean:
	rm -f $(OBJ_CPP) $(OBJ_ASM) $(TARGET)

# Пересборка
rebuild: clean all