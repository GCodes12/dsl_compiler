%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
extern int yylex();
void yyerror(const char *s);

FILE *py_code;
int plot_counter = 0;
%}

%union {
    char* str;
}

%token <str> IDENTIFIER NUMBER STRING
%token LOAD SAVE FILTER SELECT DROP RENAME REPLACE FILLNA GROUPBY SORT JOIN
%token PREPROCESS TRAIN EVALUATE SHOW DELETE DELETE_ROWS
%token MEAN MEDIAN MODE STD VAR MIN MAX COUNT CORR COV
%token LINEAR_REGRESSION KNN SVM DECISION_TREE RANDOM_FOREST KMEANS
%token PLOT HISTOGRAM SCATTER BOXPLOT BAR
%token AND OR NOT
%token GT LT GE LE EQ NE
%token BY WITH ON AS IN TO FROM WHERE OF

%%

program:
    statements
    ;

statements:
    statements statement
    | statement
    ;

statement:
      load_stmt
    | save_stmt
    | filter_stmt
    | select_stmt
    | drop_stmt
    | rename_stmt
    | replace_stmt
    | fillna_stmt
    | groupby_stmt
    | sort_stmt
    | join_stmt
    | preprocess_stmt
    | train_stmt
    | evaluate_stmt
    | show_stmt
    | delete_rows_stmt
    | stat_func_stmt
    | plot_stmt
    ;

load_stmt:
    LOAD STRING {
        fprintf(py_code, "df = pd.read_csv(\"%s\")\n", $2);
    }
;

save_stmt:
    SAVE STRING {
        char* filename = strdup($2);
        char* ext = strrchr(filename, '.');
        if (ext && strcmp(ext, ".py") == 0) {
            strcpy(ext, ".csv");
        }
        fprintf(py_code, "df.to_csv(\"%s\", index=False)\n", filename);
        free(filename);
    }
;

filter_stmt:
    FILTER IDENTIFIER GT NUMBER { fprintf(py_code, "df = df[df[\"%s\"] > %s]\n", $2, $4); }
;

select_stmt:
    SELECT IDENTIFIER { fprintf(py_code, "df = df[[\"%s\"]]\n", $2); }
;

drop_stmt:
    DROP IDENTIFIER { fprintf(py_code, "df.drop(columns=[\"%s\"], inplace=True)\n", $2); }
;

rename_stmt:
    RENAME IDENTIFIER TO IDENTIFIER { fprintf(py_code, "df.rename(columns={\"%s\": \"%s\"}, inplace=True)\n", $2, $4); }
;

replace_stmt:
    REPLACE IDENTIFIER WITH NUMBER { fprintf(py_code, "df[\"%s\"].replace(to_replace=None, value=%s, inplace=True)\n", $2, $4); }
;

fillna_stmt:
    FILLNA IDENTIFIER WITH NUMBER { fprintf(py_code, "df[\"%s\"].fillna(%s, inplace=True)\n", $2, $4); }
;

groupby_stmt:
    GROUPBY IDENTIFIER { fprintf(py_code, "df.groupby(\"%s\")\n", $2); }
;

sort_stmt:
    SORT BY IDENTIFIER { fprintf(py_code, "df.sort_values(by=\"%s\", inplace=True)\n", $3); }
;

join_stmt:
    JOIN IDENTIFIER ON IDENTIFIER { fprintf(py_code, "df = df.merge(%s, on=\"%s\")\n", $2, $4); }
;

preprocess_stmt:
    PREPROCESS { fprintf(py_code, "# Add preprocessing steps here\n"); }
;

train_stmt:
    TRAIN WITH LINEAR_REGRESSION {
        fprintf(py_code, "from sklearn.linear_model import LinearRegression\n");
        fprintf(py_code, "model = LinearRegression()\nmodel.fit(X_train, y_train)\n");
    }
    | TRAIN WITH KNN {
        fprintf(py_code, "from sklearn.neighbors import KNeighborsClassifier\n");
        fprintf(py_code, "model = KNeighborsClassifier(n_neighbors=5)\nmodel.fit(X_train, y_train)\n");
    }
    | TRAIN WITH SVM {
        fprintf(py_code, "from sklearn.svm import SVC\n");
        fprintf(py_code, "model = SVC()\nmodel.fit(X_train, y_train)\n");
    }
    | TRAIN WITH DECISION_TREE {
        fprintf(py_code, "from sklearn.tree import DecisionTreeClassifier\n");
        fprintf(py_code, "model = DecisionTreeClassifier()\nmodel.fit(X_train, y_train)\n");
    }
    | TRAIN WITH RANDOM_FOREST {
        fprintf(py_code, "from sklearn.ensemble import RandomForestClassifier\n");
        fprintf(py_code, "model = RandomForestClassifier()\nmodel.fit(X_train, y_train)\n");
    }
    | TRAIN WITH KMEANS {
        fprintf(py_code, "from sklearn.cluster import KMeans\n");
        fprintf(py_code, "model = KMeans(n_clusters=3)\nmodel.fit(X_train)\n");
    }
;

evaluate_stmt:
    EVALUATE { fprintf(py_code, "# Add evaluation metrics here\n"); }
;

show_stmt:
    SHOW { fprintf(py_code, "print(df.head())\n"); }
;

delete_rows_stmt:
    DELETE_ROWS WHERE IDENTIFIER GT NUMBER {
        fprintf(py_code, "df = df[df[\"%s\"] <= %s]\n", $3, $5);
    }
;

stat_func_stmt:
      SHOW MEAN OF IDENTIFIER   { fprintf(py_code, "print(\"Mean of %s:\", df[\"%s\"].mean())\n", $4, $4); }
    | SHOW MEDIAN OF IDENTIFIER { fprintf(py_code, "print(\"Median of %s:\", df[\"%s\"].median())\n", $4, $4); }
    | SHOW MODE OF IDENTIFIER   { fprintf(py_code, "print(\"Mode of %s:\", df[\"%s\"].mode())\n", $4, $4); }
    | SHOW STD OF IDENTIFIER    { fprintf(py_code, "print(\"Standard Deviation of %s:\", df[\"%s\"].std())\n", $4, $4); }
    | SHOW VAR OF IDENTIFIER    { fprintf(py_code, "print(\"Variance of %s:\", df[\"%s\"].var())\n", $4, $4); }
    | SHOW MIN OF IDENTIFIER    { fprintf(py_code, "print(\"Minimum of %s:\", df[\"%s\"].min())\n", $4, $4); }
    | SHOW MAX OF IDENTIFIER    { fprintf(py_code, "print(\"Maximum of %s:\", df[\"%s\"].max())\n", $4, $4); }
    | SHOW COUNT OF IDENTIFIER  { fprintf(py_code, "print(\"Count of %s:\", df[\"%s\"].count())\n", $4, $4); }
    | SHOW CORR OF IDENTIFIER   { fprintf(py_code, "print(\"Correlation of %s:\", df[\"%s\"].corr())\n", $4, $4); }
    | SHOW COV OF IDENTIFIER    { fprintf(py_code, "print(\"Covariance of %s:\", df[\"%s\"].cov())\n", $4, $4); }
;


plot_stmt:
      PLOT HISTOGRAM OF IDENTIFIER {
          fprintf(py_code, "df[\"%s\"].hist()\n", $4);
          fprintf(py_code, "plt.savefig(\"plots/plot_%%d.png\" %% %d)\n", plot_counter++);
          fprintf(py_code, "plt.clf()\n");
      }
    | PLOT SCATTER OF IDENTIFIER {
          fprintf(py_code, "df.plot.scatter(x=\"%s\", y=\"%s\")\n", $4, $4);
          fprintf(py_code, "plt.savefig(\"plots/plot_%%d.png\" %% %d)\n", plot_counter++);
          fprintf(py_code, "plt.clf()\n");
      }
    | PLOT BOXPLOT OF IDENTIFIER {
          fprintf(py_code, "df.boxplot(column=\"%s\")\n", $4);
          fprintf(py_code, "plt.savefig(\"plots/plot_%%d.png\" %% %d)\n", plot_counter++);
          fprintf(py_code, "plt.clf()\n");
      }
    | PLOT BAR OF IDENTIFIER {
          fprintf(py_code, "df[\"%s\"].value_counts().plot.bar()\n", $4);
          fprintf(py_code, "plt.savefig(\"plots/plot_%%d.png\" %% %d)\n", plot_counter++);
          fprintf(py_code, "plt.clf()\n");
      }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
