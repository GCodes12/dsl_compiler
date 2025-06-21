#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dsl_parser.tab.h"

extern FILE *yyin;
extern FILE *py_code;
extern int yyparse();

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input.dsl> [output.py]\n", argv[0]);
        return 1;
    }

    // Open input DSL file
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error opening input file");
        return 1;
    }

    // Output file (default to "output.py" if not specified)
    const char *out_filename = (argc >= 3) ? argv[2] : "output.py";
    py_code = fopen(out_filename, "w");
    if (!py_code) {
        perror("Error opening output file");
        fclose(yyin);
        return 1;
    }

    // Write default Python imports
    fprintf(py_code, "import pandas as pd\n");
    fprintf(py_code, "import matplotlib.pyplot as plt\n");

    // Parse the DSL file
    if (yyparse() != 0) {
        fprintf(stderr, "Parsing failed.\n");
        fclose(yyin);
        fclose(py_code);
        return 1;
    }

    fclose(yyin);
    fclose(py_code);

    // Run the generated Python script
    char cmd[300];
    snprintf(cmd, sizeof(cmd), "python3 %s", out_filename);
    system(cmd);

    return 0;
}
