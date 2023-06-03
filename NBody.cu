// I believe that the speedup is similar to Ahmdal’s Law because it argues that if the issue size is increased accordingly, the speedup of a parallel program is proportional to the number of processors. In other words,  Ahmdal’s law says that the speedup factor should roughly remain constant if the size of the problem grows as the number of processors increases and it does.

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define N 9999                // number of bodies
#define MASS 0                // row in array for mass
#define X_POS 1               // row in array for x position
#define Y_POS 2               // row in array for y position
#define Z_POS 3               // row in array for z position
#define X_VEL 4               // row in array for x velocity
#define Y_VEL 5               // row in array for y velocity
#define Z_VEL 6               // row in array for z velocity
#define G 200                 // "gravitational constant" (not really)
#define MU 0.001              // "frictional coefficient"
#define BOXL 100.0            // periodic boundary box length
__constant__ float dt = 0.05; // time interval
float body[10000][7];         // data array of bodies

__global__ void force_calc(float *body)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j;
    float dx, dy, dz, r, fx, fy, fz;

    fx = fy = fz = 0.0;

    for (j = 0; j < N; j++)
    {
        if (i == j)
            continue;

        dx = body[j * 7 + X_POS] - body[i * 7 + X_POS];
        dy = body[j * 7 + Y_POS] - body[i * 7 + Y_POS];
        dz = body[j * 7 + Z_POS] - body[i * 7 + Z_POS];

        r = sqrt(dx * dx + dy * dy + dz * dz);

        fx += G * body[i * 7 + MASS] * body[j * 7 + MASS] * dx / (r * r * r);
        fy += G * body[i * 7 + MASS] * body[j * 7 + MASS] * dy / (r * r * r);
        fz += G * body[i * 7 + MASS] * body[j * 7 + MASS] * dz / (r * r * r);
    }

    body[i * 7 + X_VEL] += dt * fx / body[i * 7 + MASS] - MU * body[i * 7 + X_VEL];
    body[i * 7 + Y_VEL] += dt * fy / body[i * 7 + MASS] - MU * body[i * 7 + Y_VEL];
    body[i * 7 + Z_VEL] += dt * fz / body[i * 7 + MASS] - MU * body[i * 7 + Z_VEL];

    body[i * 7 + X_POS] += dt * body[i * 7 + X_VEL];
    body[i * 7 + Y_POS] += dt * body[i * 7 + Y_VEL];
    body[i * 7 + Z_POS] += dt * body[i * 7 + Z_VEL];
}
int main(int argc, char **argv)
{
    if (argc != 2)
    {
        printf("Usage: %s <timesteps>\n", argv[0]);
        return 1;
    }
    int tmax = atoi(argv[1]);
    int i, j;
    float x, y, z;

    // initialize body array
    for (i = 0; i < N; i++)
    {
        body[i][MASS] = 1.0;
        // Generate initial coordinates centered on origin, ranging -150.0 to +150.0
        body[i][X_POS] = ((float)rand() / RAND_MAX * 300.0) - 150.0;
        body[i][Y_POS] = ((float)rand() / RAND_MAX * 300.0) - 150.0;
        body[i][Z_POS] = ((float)rand() / RAND_MAX * 300.0) - 150.0;
        body[i][X_VEL] = 0.0;
        body[i][Y_VEL] = 0.0;
        body[i][Z_VEL] = 0.0;
    }

    // allocate memory on device and copy data
    float *d_body;
    cudaMalloc(&d_body, N * 7 * sizeof(float));
    cudaMemcpy(d_body, body, N * 7 * sizeof(float), cudaMemcpyHostToDevice);

    // launch kernel for each timestep
    int num_blocks = (N + 255) / 256;
    dim3 grid(num_blocks, 1, 1);
    dim3 block(256, 1, 1);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    FILE *fp;
    fp = fopen("NBody.pdb", "w");
    for (i = 0; i < tmax; i++)
    {
        cudaEventRecord(start);
        force_calc<<<grid, block>>>(d_body);
        cudaEventRecord(stop);
        cudaMemcpy(body, d_body, N * 7 * sizeof(float), cudaMemcpyDeviceToHost);
        float elapsedTime;
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&elapsedTime, start, stop);
        printf("Time taken by program: %f seconds\n", elapsedTime / 1000);

        FILE *fp2 = fopen("cu_exec_time.csv", "a");
        if (fp2 == NULL)
        {
            printf("Error opening file\n");
            return 1;
        }

        fprintf(fp2, "%.8f,%d\n", elapsedTime / 1000, tmax);
        fclose(fp2);
 
        fprintf(fp, "MODEL %8d\n", i + 1);
        for (j = 0; j < N; j++)
        {
            fprintf(fp, "%s%7d  %s %s %s%4d    %8.3f%8.3f%8.3f  %4.2f  %4.3f\n",
                    "ATOM", j + 1, "CA ", "GLY", "A", j + 1, body[j][X_POS], body[j][Y_POS], body[j][Z_POS], 1.00, 0.00);
        }
        fprintf(fp, "TER\nENDMDL\n");

        // print progress
        if ((i + 1) % 100 == 0)
        {
            printf("Timestep %d of %d completed\n", i + 1, tmax);
        }
    }

    fclose(fp);
    cudaFree(d_body);

    return 0;
}