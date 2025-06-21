# Use a base image with build tools
FROM ubuntu:latest

# Install system dependencies
RUN apt-get update && \
    apt-get install -y flex bison gcc g++ python3 python3-pip nodejs npm && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy everything into the container
COPY . .

# Install Node.js dependencies
RUN npm install

# Compile the C-based DSL compiler
RUN cd compiler && \
    bison -d dsl_parser.y && \
    flex dsl_lexer.l && \
    gcc -o dsl_compiler lex.yy.c dsl_parser.tab.c main.c -lm

# Expose the port for the Node.js server
EXPOSE 3000

# Run the server
CMD ["node", "server.js"]
