#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s file1.csv file2.csv\n", argv[0]);
        return 1;
    }

    FILE *file1 = fopen(argv[1], "r");
    FILE *file2 = fopen(argv[2], "r");
    FILE *speedup_file = fopen("SpeedUp.csv", "w");

    if (!file1 || !file2 || !speedup_file) {
        printf("Error: could not open input or output files.\n");
        return 1;
    }

    char line1[1024];
    char line2[1024];
    int i = 0;

    while (fgets(line1, sizeof(line1), file1) && fgets(line2, sizeof(line2), file2)) {
        double val1 = atof(strtok(line1, ","));
        double val2 = atof(strtok(line2, ","));
        double speedup = val1 / val2;
        double val2_file2 = atof(strtok(NULL, ","));
        fprintf(speedup_file, "%.10f,%.10f\n", speedup, i);
        i++;
    }

    fclose(file1);
    fclose(file2);
    fclose(speedup_file);

    return 0;
}