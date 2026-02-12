# While Language Compiler

A multipass compiler for the "While" educational programming language, developed in C++ using Flex and Bison.

## Project Structure

This repository demonstrates the staged development of the compiler:

* **01_Lexer**: Lexical analysis using Flex.
* **02_Parser**: Syntax analysis and AST (abstract syntax tree) construction using Bison.
* **03_Semantics**: Symbol table generation and type checking.
* **04_Final_CodeGen**: Code generation (targeting ASM/Intermediate representation).

## Features

* **Control Flow**: Support for `while` and `for` loops, `if/else` statements.
* **Data Types**: Integers, Booleans, Strings, Time.
* **Scoping**: Variable declarations and scope management.
* **Error Handling**: Detection of lexical, syntax, and semantic errors.

## Prerequisites

To build this project, you need:

* `g++` or `clang++`
* `flex`
* `bison`
* `make`

## How to Build and Run

Navigate to the final stage (or any specific stage):

```bash
cd 04_Final_CodeGen
make
```

This will compile the source files and generate an executable binary named `while`.

You can run the compiler by passing a source file as an argument or by piping input via standard in.

Using a file path:

```bash
./while tests/01.ok
```

Using input redirection:

```bash
./while < tests/01.ok
```

## Testing

Each stage includes a `tests/` directory containing:

* `*.ok` files: Valid code that should compile successfully.
* `*.error` files: Invalid code that should trigger specific error messages.

To verify the compiler works as expected, run it against these files.

