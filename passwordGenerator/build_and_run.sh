#!/bin/bash

# Check for arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <filename_without_extension> [other_files...] [-- program_arguments]"
    exit 1
fi

# Separate file list and program arguments
FILES=()
ARGS=()
SEEN_DASHDASH=0

for arg in "$@"; do
    if [ "$arg" == "--" ]; then
        SEEN_DASHDASH=1
        continue
    fi

    if [ $SEEN_DASHDASH -eq 0 ]; then
        FILES+=("$arg")         # Add to list of source files
    else
        ARGS+=("$arg")          # Add to list of arguments passed to the final executable
    fi
done

# Create "ready" directory if it doesn't exist
mkdir -p ready

# Handle the single-file case
if [ ${#FILES[@]} -eq 1 ]; then
    SOURCE="${FILES[0]}.asm"           # Source file (e.g., file.asm)
    OBJ="ready/${FILES[0]}.o"          # Object file
    OUT="ready/${FILES[0]}"            # Output executable

    # Assemble the source file with NASM
    nasm -f elf64 -o "$OBJ" "$SOURCE"
    if [ $? -ne 0 ]; then
        echo "NASM compilation error"
        exit 1
    fi

    # Link the object file into an executable
    ld -o "$OUT" "$OBJ"
    if [ $? -ne 0 ]; then
        echo "Linking error"
        exit 1
    fi

    echo "=== Program output: ==="
    ./"$OUT" "${ARGS[@]}"              # Run the executable with arguments
    echo "Return code: $?"
    exit 0
fi

# Handle multiple files
OBJ_FILES=()
for file in "${FILES[@]}"; do
    ASM_FILE="${file}.asm"
    OBJ_FILE="ready/${file}.o"

    if [ ! -f "$ASM_FILE" ]; then
        echo "File $ASM_FILE not found"
        exit 1
    fi

    # Assemble each .asm file
    nasm -f elf64 -o "$OBJ_FILE" "$ASM_FILE"
    if [ $? -ne 0 ]; then
        echo "Compilation error in $ASM_FILE"
        exit 1
    fi

    OBJ_FILES+=("$OBJ_FILE")
done

OUT="ready/library"           # Name of the output executable for multiple files

# Link all object files into one executable
ld -o "$OUT" "${OBJ_FILES[@]}"
if [ $? -ne 0 ]; then
    echo "Linking error"
    exit 1
fi

echo "=== Program output: ==="
./"$OUT" "${ARGS[@]}"         # Run the combined executable with arguments
echo "Return code: $?"
