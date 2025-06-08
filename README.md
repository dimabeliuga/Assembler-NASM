# Assembly Programming Projects

This repository contains a collection of assembly language projects written in **NASM** for **Linux systems**. The projects demonstrate various concepts such as string manipulation, file operations, sorting algorithms, and user input handling.


## Projects Overview

### 1. Library

The Library directory contains a library catalog management program that allows users to manage a collection of books. It supports adding, removing, lending, returning, searching, sorting, and saving/loading books to/from a file.


Features:

- Add new books to the catalog.

- Display all books.

- Lend or return books.

- Remove books from the catalog.

- Search for books by title.
  
- Sort books by title using insertion sort.

- Save and load books to/from a file.

- Clear screen and menu-based navigation.


Files:

- `main.asm`: Main program logic with a menu-driven interface.

- `find_book.asm`: Functions to search for books by title.

- `input.asm`: Functions for handling user input.

- `output.asm`: Functions for displaying book information.

- `save_load_file.asm`: Functions for saving and loading books to/from a file.

- `sort_books.asm`: Implementation of insertion sort for sorting books by title.

- `str_book.inc`: Structure definitions for the book data.

- `utils.asm`: Utility functions for string manipulation and file operations.

- `build_and_run.sh`: Script to compile and run the program.
  

**How to Run:**
```bash
cd Library
./build_and_run.sh [all files] [parametrs(optional)]
```


### 2. passwordGenerator

The passwordGenerator directory contains a program that generates random passwords based on user-specified criteria, such as length, character types, and output to a file.

Files:

- `main.asm`: Main program logic for parsing command-line arguments and controlling execution.

- `gen.asm`: Functions for generating random passwords.

- `password.asm`: Functions for building character sets and handling password output.

- `utils.asm`: Utility functions for file operations and string parsing.

- `macroses.inc`: Macro definitions for string and system call operations.

- `build_and_run.sh`: Script to compile and run the program.


Features:

- Generate passwords with customizable length (1-256 characters).
  
- Include/exclude lowercase, uppercase, numbers, and special symbols.

- Specify the number of passwords to generate (1-20).

- Option to save passwords to a file.

- Uses /dev/urandom for random data generation.

- Error handling for invalid inputs and file operations.

***How to Run:***
``` bash
cd passwordGenerator
./build_and_run.sh [all files(without .asm)] [parametrs (optional)]
```

***Example:***
```bash
./build_and_run.sh -s 16 -c 5 -file passwords.txt
```


### 3. SmallProjects

The SmallProjects directory contains a collection of small assembly programs demonstrating basic concepts and algorithms.

Files:

- `arrayOutput.asm`: Program to input and sort an array of numbers, then output the sorted array.

- `bubbleSort.asm`: Implementation of the bubble sort algorithm for sorting numbers.

- `cmdProcessing.asm`: Program to process command-line arguments and perform arithmetic operations on floating-point numbers.

- `loopOutput.asm`: Simple program to print a sequence of numbers using a loop.

- `outInFileCFunctions.asm`: Program demonstrating file output using C library functions (fopen, fputs, fclose).

- `build_and_run.sh`: Script to compile and run the selected program.


Features:

- `arrayOutput.asm`: Accepts user input for numbers, sorts them using selection sort, and prints the sorted array.

- `bubbleSort.asm`: Implements bubble, selection, insert and quick sort algorithms for sorting an array of integers.

- `cmdProcessing.asm`: Performs addition, subtraction, multiplication, and division on two floating-point numbers provided as command-line arguments.

- `loopOutput.asm`: Outputs a sequence of numbers (0 to 77) with a "Symbol: " prefix.

- `outInFileCFunctions.asm`: Writes "Hello World" to a file using C library functions.


***How to Run:***

```bash
cd SmallProjects
./build_and_run.sh
```


Requirements

- `NASM` : The Netwide Assembler for compiling assembly code.

- Linux: The programs are designed for Linux systems using x86-64 architecture.

- GCC: Required for linking programs that use C library functions (e.g., outInFileCFunctions.asm).

- Standard Libraries: Ensure libc is available for programs using C functions.



### Install NASM and GCC:

```bash 
sudo apt update
sudo apt install nasm gcc
```

Clone the repository:

```bash
git clone <repository-url>
cd <repository-name>
```

Navigate to the desired project directory and use the provided build_and_run.sh script to compile and run.

### Usage

Each project directory contains a build_and_run.sh script that compiles the assembly files and links them into an executable. The script assumes NASM and GCC are installed. For specific usage instructions, refer to the "How to Run" section for each project above.


### Contributing

Contributions are welcome! Feel free to open issues or submit pull requests for bug fixes, improvements, or new features.

### License

This project is licensed under the MIT License. See the LICENSE file for details.
