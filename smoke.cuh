#ifndef SMOKE_H
#define SMOKE_H


#include "CSCIx229.h"
#include <stdlib.h>

//variables

extern int N; //size in one direction
extern int size; //total particles
//velocities (v1 = x, v2 = y, v3 = z)
extern float * v1;
extern float * v2;
extern float * v3;
//previous velocities
extern float * v1_prev;
extern float * v2_prev;
extern float * v3_prev;
//densities
extern float * dens;
extern float * dens_prev;
//other constants
extern float visc;
extern float dt;
extern float diff;
//Sets k, the iteration count for the iterative solvers
extern int K;

//TODO Source Vector

//Gives index into vectors from x, y, z coordinates
int IX(int x, int y, int z);

//Swap arrays using pointers
void swap(float *&a, float *&b);

//Diffuse
__global__
void diffuse (int b, float x[], float x0[]);

//Advect
__global__
void advect (int b, float d[], float d0[], float v1[], float v2[], float v3[]);

//Density Step
void dens_step (float x[], float x0[], float v1[], float v2[], float v3[]);

//Velocity Steps
void vel_step (float v1[], float v2[], float v3[], float v1_prev[], float v2_prev[], float v3_prev[]);

//Project, ensure boundary conditions
__global__
void projectNS (float v1[], float v2[], float v3[], float p[], float div[]);

//Set bounds
__device__
void set_bnd (int b, float x[]);

//Draw
void draw_smoke();

//Run progression and call draw_smoke()
void run_smoke();

//setup
void setup();

//Clean Up
void cleanup();

#endif /* SMOKE_H */
