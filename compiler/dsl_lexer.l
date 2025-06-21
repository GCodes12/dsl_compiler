%{
#include "dsl_parser.tab.h"
#include <string.h>
#include <stdlib.h>
%}

IDENTIFIER   [a-zA-Z_][a-zA-Z0-9_]*
NUMBER       [0-9]+(\.[0-9]+)?
STRING       \"[^\"]*\"

%%

"LOAD"              { return LOAD; }
"SAVE"              { return SAVE; }
"FILTER"            { return FILTER; }
"SELECT"            { return SELECT; }
"DROP"              { return DROP; }
"RENAME"            { return RENAME; }
"REPLACE"           { return REPLACE; }
"FILLNA"            { return FILLNA; }
"GROUPBY"           { return GROUPBY; }
"SORT"              { return SORT; }
"JOIN"              { return JOIN; }
"PREPROCESS"        { return PREPROCESS; }
"TRAIN"             { return TRAIN; }
"EVALUATE"          { return EVALUATE; }
"SHOW"              { return SHOW; }
"DELETE"            { return DELETE; }
"DELETE_ROWS"       { return DELETE_ROWS; }

"MEAN"              { return MEAN; }
"MEDIAN"            { return MEDIAN; }
"MODE"              { return MODE; }
"STD"               { return STD; }
"VAR"               { return VAR; }
"MIN"               { return MIN; }
"MAX"               { return MAX; }
"COUNT"             { return COUNT; }
"CORR"              { return CORR; }
"COV"               { return COV; }

"LINEAR_REGRESSION" { return LINEAR_REGRESSION; }
"KNN"               { return KNN; }
"SVM"               { return SVM; }
"DECISION_TREE"     { return DECISION_TREE; }
"RANDOM_FOREST"     { return RANDOM_FOREST; }
"KMEANS"            { return KMEANS; }

"PLOT"              { return PLOT; }
"HISTOGRAM"         { return HISTOGRAM; }
"SCATTER"           { return SCATTER; }
"BOXPLOT"           { return BOXPLOT; }
"BAR"               { return BAR; }

"AND"               { return AND; }
"OR"                { return OR; }
"NOT"               { return NOT; }

">="                { return GE; }
"<="                { return LE; }
"=="                { return EQ; }
"!="                { return NE; }
">"                 { return GT; }
"<"                 { return LT; }

"BY"                { return BY; }
"WITH"              { return WITH; }
"ON"                { return ON; }
"AS"                { return AS; }
"IN"                { return IN; }
"TO"                { return TO; }
"FROM"              { return FROM; }
"WHERE"             { return WHERE; }
"OF"                { return OF; }

{NUMBER}            { yylval.str = strdup(yytext); return NUMBER; }
{STRING}            {
                        yylval.str = strdup(yytext + 1);
                        yylval.str[strlen(yylval.str) - 1] = '\0';
                        return STRING;
                    }
{IDENTIFIER}        { yylval.str = strdup(yytext); return IDENTIFIER; }

[ \t\r\n]+          { /* skip whitespace */ }
.                   { printf("Unknown character: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}
