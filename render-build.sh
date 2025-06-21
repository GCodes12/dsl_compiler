#!/bin/bash
echo "🔧 Building DSL Compiler..."

cd compiler

# Step 1: Generate parser code from Bison
bison -d dsl_parser.y

# Step 2: Generate lexer code from Flex
flex dsl_lexer.l

# Step 3: Compile using gcc (C)
gcc -o dsl_compiler lex.yy.c dsl_parser.tab.c main.c -lfl

cd ..
echo "✅ Compiler built successfully."
