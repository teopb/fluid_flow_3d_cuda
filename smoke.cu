#include "smoke.cuh"
#include <stdio.h>

//variables

#define N 64 //size in one direction
//Sets k, the iteration count for the iterative solvers
#define K1 5
#define K2 10

#define T 256

//other constants
#define visc .01
#define dt .02
#define diff .01

int size; //total particles
//velocities (v1 = x, v2 = y, v3 = z)
float *v1, *v2, *v3;
//previous velocities
float *v1_prev, *v2_prev, *v3_prev;
//densities
float *dens, *dens_prev;
//other constants

int sourceCount = 0;

//Gives index into vectors from x, y, z coordinates
int IX(int x, int y, int z){
  //N+2 for boundaries
  return x + (N+2)*y + (N+2)*(N+2)*z;
}

//Swap arrays using pointers
void swap(float *&a, float *&b){
  float *temp = a;
  a = b;
  b = temp;
  return;
}

//Diffuse
__global__
void diffuse (int b, float x[], float x0[]){
  int divisor = blockDim.x/N;
  int index_i = threadIdx.x % N + 1;
  int index_j = threadIdx.x / N + 1;
  float a = dt * diff * N * N * N;
  for (size_t k = 0; k < K1; k++) {
    for (size_t l = 1; l <= N; l++) {
      for (size_t j = index_j; j <= N; j += divisor) {
        for (size_t i = index_i; i <= N; i += N){
          x[i + (N+2)*( j) + (N+2)*(N+2)*( l)] = (x0[i + (N+2)*( j) + (N+2)*(N+2)*( l)] + a*(x[i-1 + (N+2)*( j) + (N+2)*(N+2)*( l)] + x[i+1 + (N+2)*( j) + (N+2)*(N+2)*( l)] + x[i + (N+2)*( j-1) + (N+2)*(N+2)*( l)] + x[i + (N+2)*( j+1) + (N+2)*(N+2)*( l)]+ x[i + (N+2)*( j) + (N+2)*(N+2)*( l-1)] + x[i + (N+2)*( j) + (N+2)*(N+2)*( l+1)]))/(1+6*a);
        }
      }
    }
    set_bnd(b, x);
  }
  return;
}

//Advect
__global__
void advect (int b, float d[], float d0[], float v1[], float v2[], float v3[]){
  int divisor = blockDim.x/N;
  int index_i = threadIdx.x % N + 1;
  int index_j = threadIdx.x / N + 1;
  int i0, j0, l0, i1, j1, l1;
  float x, y, z, x0, x1, y0, y1, z0, z1;
  float dt_scaled = dt*N;
  //printf("In advect 1\n");
  for (size_t l = 1; l <= N; l++) {
    for (size_t j = index_j; j <= N; j += divisor) {
      for (size_t i = index_i; i <= N; i += N) {
        // try
        // {
          //backsolves for location of particle that ended up at final location
          x = i - dt_scaled * v1[i + (N+2)*( j) + (N+2)*(N+2)*( l)];
          y = j - dt_scaled * v2[i + (N+2)*( j) + (N+2)*(N+2)*( l)];
          z = l - dt_scaled * v3[i + (N+2)*( j) + (N+2)*(N+2)*( l)];

          //enforces boundary conditions
          if (x < 0.5) x = 0.5;
          if (x > N + 0.5) x = N+ 0.5;

          //set i0, i1 to  integer boundaries around x
          i0 = static_cast<int>(x);
          i1 = i0+1;

          //Same for y and z
          if (y < 0.5) y = 0.5;
          if (y > N + 0.5) y = N+ 0.5;
          j0 = static_cast<int>(y);
          j1 = j0+1;

          if (z < 0.5) z = 0.5;
          if (z > N + 0.5) z = N+ 0.5;
          l0 = static_cast<int>(z);
          l1 = l0+1;

          //get relative positions in cell
          x1 = x - i0;
          x0 = 1 - x1;

          y1 = y - j0;
          y0 = 1 - y1;

          z1 = z - l0;
          z0 = 1 - z1;


          //Using relative positions set new density as a weighted combination of the contributing cells
          //TODO this might have to be modified given change from 2D
          d[i + (N+2)*( j) + (N+2)*(N+2)*( l)] =
          x0 * (y0 * (z0 * d0[i0 + (N+2)*( j0) + (N+2)*(N+2)*( l0)] + z1 * d0[i0 + (N+2)*( j0) + (N+2)*(N+2)*( l1)])) +
          x0 * (y1 * (z0 * d0[i0 + (N+2)*( j1) + (N+2)*(N+2)*( l0)] + z1 * d0[i0 + (N+2)*( j1) + (N+2)*(N+2)*( l1)])) +
          x1 * (y0 * (z0 * d0[i1 + (N+2)*( j0) + (N+2)*(N+2)*( l0)] + z1 * d0[i1 + (N+2)*( j0) + (N+2)*(N+2)*( l1)])) +
          x1 * (y1 * (z0 * d0[i1 + (N+2)*( j1) + (N+2)*(N+2)*( l0)] + z1 * d0[i1 + (N+2)*( j1) + (N+2)*(N+2)*( l1)]));
        // }
        // catch(...)
        // {
        //   printf("error i0 = %d, j0 = %d, l0 = %d\n", i0, j0, l0);
        //   printf("error i1 = %d, j1 = %d, l1 = %d\n", i1, j1, l1);
        //   printf("dt_scaled = %f\n", dt_scaled);
        //   printf("x = %f, y = %f, z= %f\n", x, y, z);
        //   printf("v1 = %f, v2 = %f, v3= %f\n", v1[IX(i, j, l)], v2[IX(i, j, l)], v3[IX(i, j, l)]);
        //
        //   exit(1);
        // }
      }
    }
  }
  //printf("In advect 3\n");
  set_bnd(b, d);
  return;
}

//Density Step
void dens_step ( float x[], float x0[], float v1[], float v2[], float v3[]){
  //printf("In dens_step\n");
  diffuse<<<1, T>>>(0, x, x0);
  cudaDeviceSynchronize();
  //printf("In dens_step 2\n");
  swap(x, x0);
  //printf("In dens_step 3\n");
  advect<<<1, T>>>(0, x, x0, v1, v2, v3);
  cudaDeviceSynchronize();
  //printf("In dens_step 4\n");
  swap(x0, x);
  //cudaDeviceSynchronize();
  //printf("leaving dens_step\n");
  return;
}

//Velocity Steps
void vel_step (float v1[], float v2[], float v3[], float v1_prev[], float v2_prev[], float v3_prev[]){
  //printf("In vel_step\n");
  swap(v1, v1_prev);
  diffuse<<<1, T>>>(1, v1, v1_prev);
  //cudaDeviceSynchronize();
  //printf("In vel_step2\n");
  swap(v2, v2_prev);
  diffuse<<<1, T>>>(2, v2, v2_prev);
  //cudaDeviceSynchronize();
  swap(v3, v3_prev);
  diffuse<<<1, T>>>(3, v3, v3_prev);
  cudaDeviceSynchronize();

  //Not confident in this adjustment to 3d
  //printf("In vel_step3\n");
  projectNS<<<1, T>>>(v1, v2, v3, v1_prev, v2_prev);
  cudaDeviceSynchronize();

  swap(v1, v1_prev);
  swap(v2, v2_prev);
  swap(v3, v3_prev);
  //printf("In vel_step4\n");
  advect<<<1, T>>>(1, v1, v1_prev, v1_prev, v2_prev, v3_prev);
  //cudaDeviceSynchronize();
  advect<<<1, T>>>(2, v2, v2_prev, v1_prev, v2_prev, v3_prev);
  //cudaDeviceSynchronize();
  advect<<<1, T>>>(3, v3, v3_prev, v1_prev, v2_prev, v3_prev);
  //TODO possibly synch more
  cudaDeviceSynchronize();
  //printf("In vel_step5\n");
  projectNS<<<1, T>>>(v1, v2, v3, v1_prev, v2_prev);
  cudaDeviceSynchronize();
  //printf("leaving vel_step\n");
  return;
}

//Project, ensure boundary conditions
__global__
void projectNS (float v1[], float v2[], float v3[], float p[], float div[]){
  int divisor = blockDim.x/N;
  int index_i = threadIdx.x % N + 1;
  int index_j = threadIdx.x / N + 1;

  float h = 1.0/N;

  for (size_t l = 1; l <= N; l ++) {
    for (size_t j = index_j; j <= N; j += divisor) {
      for (size_t i = index_i; i <= N; i += N) {
        div[i + (N+2)*( j) + (N+2)*(N+2)*( l)] = -0.5 * h * (v1[i+1 + (N+2)*( j) + (N+2)*(N+2)*( l)] - v1[i-1 + (N+2)*( j) + (N+2)*(N+2)*( l)]
        + v2[i + (N+2)*( j+1) + (N+2)*(N+2)*( l)] - v2[i + (N+2)*( j-1) + (N+2)*(N+2)*( l)]
        + v3[i + (N+2)*( j) + (N+2)*(N+2)*( l+1)] - v3[i + (N+2)*( j) + (N+2)*(N+2)*( l-1)]);
        p[i + (N+2)*( j) + (N+2)*(N+2)*( l)] = 0;
      }
    }
  }

  set_bnd(0, p);
  set_bnd(0, div);

  for (size_t k = 0; k < K2; k++) {
    for (size_t l = 1; l <= N; l ++) {
      for (size_t j = index_j; j <= N; j += divisor) {
        for (size_t i = index_i; i <= N; i += N) {
          p[i + (N+2)*( j) + (N+2)*(N+2)*( l)] = (div[i + (N+2)*( j) + (N+2)*(N+2)*( l)] + p[i+1 + (N+2)*( j) + (N+2)*(N+2)*( l)] + p[i-1 + (N+2)*( j) + (N+2)*(N+2)*( l)]
          + p[i + (N+2)*( j+1) + (N+2)*(N+2)*( l)] + p[i + (N+2)*( j-1) + (N+2)*(N+2)*( l)]
          + p[i + (N+2)*( j) + (N+2)*(N+2)*( l+1)] + p[i + (N+2)*( j) + (N+2)*(N+2)*( l-1)])/6;
        }
      }
    }
    set_bnd(0, p);
  }

  for (size_t l = 1; l <= N; l ++) {
    for (size_t j = index_j; j <= N; j += divisor) {
      for (size_t i = index_i; i <= N; i += N) {
        //making same change from substraction to addition
        v1[i + (N+2)*( j) + (N+2)*(N+2)*( l)] += 0.5 * (p[i+1 + (N+2)*( j) + (N+2)*(N+2)*( l)] - p[i-1 + (N+2)*( j) + (N+2)*(N+2)*( l)])/h;
        v2[i + (N+2)*( j) + (N+2)*(N+2)*( l)] += 0.5 * (p[i + (N+2)*( j+1) + (N+2)*(N+2)*( l)] - p[i + (N+2)*( j-1) + (N+2)*(N+2)*( l)])/h;
        v3[i + (N+2)*( j) + (N+2)*(N+2)*( l)] += 0.5 * (p[i + (N+2)*( j) + (N+2)*(N+2)*( l+1)] - p[i + (N+2)*( j) + (N+2)*(N+2)*( l-1)])/h;
      }
    }
  }
  set_bnd(1, v1);
  set_bnd(2, v2);
  set_bnd(3, v3);

  return;
}

//Set bounds
__device__
void set_bnd (int b, float x[]){
  int divisor = blockDim.x/N;
  int index_i = threadIdx.x % N + 1;
  int index_j = threadIdx.x / N + 1;
  for (size_t j = index_j; j <= N; j += divisor) {
    for (size_t i = index_i; i <= N; i += N) {
      if (b == 1) {
        x[0 + (N+2)*( i) + (N+2)*(N+2)*( j)] = -x[1 + (N+2)*( i) + (N+2)*(N+2)*( j)];
        x[N+1 + (N+2)*( i) + (N+2)*(N+2)*( j)] = -x[N + (N+2)*( i) + (N+2)*(N+2)*( j)];
      }
      else{
        x[0 + (N+2)*( i) + (N+2)*(N+2)*( j)] = x[1 + (N+2)*( i) + (N+2)*(N+2)*( j)];
        x[N+1 + (N+2)*( i) + (N+2)*(N+2)*( j)] = x[N + (N+2)*( i) + (N+2)*(N+2)*( j)];
      }
      if (b == 2) {
        x[i + (N+2)*( 0) + (N+2)*(N+2)*( j)] = -x[i + (N+2)*(1) + (N+2)*(N+2)*( j)];
        x[i + (N+2)*(N+1) + (N+2)*(N+2)*( j)] = -x[i + (N+2)*(N) + (N+2)*(N+2)*( j)];
      }
      else{
        x[i + (N+2)*( 0) + (N+2)*(N+2)*( j)] = x[i + (N+2)*( 1) + (N+2)*(N+2)*( j)];
        x[i + (N+2)*( N+1) + (N+2)*(N+2)*( j)] = x[i + (N+2)*(N) + (N+2)*(N+2)*( j)];
      }
      if (b == 3) {
        x[i + (N+2)*(j) + (N+2)*(N+2)*( 0)] = -x[i + (N+2)*( j) + (N+2)*(N+2)*( 1)];
        x[i + (N+2)*( j) + (N+2)*(N+2)*( N+1)] = -x[i + (N+2)*( j) + (N+2)*(N+2)*( N)];
      }
      else{
        x[i + (N+2)*( j) + (N+2)*(N+2)*( 0)] = x[i + (N+2)*( j) + (N+2)*(N+2)*( 1)];
        x[i + (N+2)*( j) + (N+2)*(N+2)*( N+1)] = x[i + (N+2)*( j) + (N+2)*(N+2)*( N)];
      }
    }
  }
  //for corners
  //printf("setbnd corner\n");
  if (threadIdx.x == 0) {
    x[0 + (N+2)*( 0) + (N+2)*(N+2)*( 0)] = 0.3333*(x[1 + (N+2)*( 0) + (N+2)*(N+2)*( 0)] + x[0 + (N+2)*( 1) + (N+2)*(N+2)*( 0)] + x[0 + (N+2)*( 0) + (N+2)*(N+2)*( 1)]);
    x[0 + (N+2)*( N+1) + (N+2)*(N+2)*( 0)] = 0.3333*(x[1 + (N+2)*( N+1) + (N+2)*(N+2)*( 0)] + x[0 + (N+2)*( N) + (N+2)*(N+2)*( 0)] + x[0 + (N+2)*( N+1) + (N+2)*(N+2)*( 1)]);
    x[N+1 + (N+2)*( 0) + (N+2)*(N+2)*( 0)] = 0.3333*(x[N + (N+2)*( 0) + (N+2)*(N+2)*( 0)] + x[N+1 + (N+2)*( 1) + (N+2)*(N+2)*( 0)] + x[N+1 + (N+2)*( 0) + (N+2)*(N+2)*( 1)]);
    x[N+1 + (N+2)*( N+1) + (N+2)*(N+2)*( 0)] = 0.3333*(x[N + (N+2)*( N+1) + (N+2)*(N+2)*( 0)] + x[N+1 + (N+2)*( N) + (N+2)*(N+2)*( 0)] + x[N+1 + (N+2)*( N+1) + (N+2)*(N+2)*( 1)]);
    x[0 + (N+2)*( 0) + (N+2)*(N+2)*( N+1)] = 0.3333*(x[1 + (N+2)*( 0) + (N+2)*(N+2)*( N+1)] + x[0 + (N+2)*( 1) + (N+2)*(N+2)*( N+1)] + x[0 + (N+2)*( 0) + (N+2)*(N+2)*( N)]);
    x[0 + (N+2)*( N+1) + (N+2)*(N+2)*( N+1)] = 0.3333*(x[1 + (N+2)*( N+1) + (N+2)*(N+2)*( N+1)] + x[0 + (N+2)*( N) + (N+2)*(N+2)*( N+1)] + x[0 + (N+2)*( N+1) + (N+2)*(N+2)*( N)]);
    x[N+1 + (N+2)*( 0) + (N+2)*(N+2)*( N+1)] = 0.3333*(x[N + (N+2)*( 0) + (N+2)*(N+2)*( N+1)] + x[N+1 + (N+2)*( 1) + (N+2)*(N+2)*( N+1)] + x[N+1 + (N+2)*( 0) + (N+2)*(N+2)*( N)]);
    x[N+1 + (N+2)*( N+1) + (N+2)*(N+2)*( N+1)] = 0.3333*(x[N + (N+2)*( N+1) + (N+2)*(N+2)*( N+1)] + x[N+1 + (N+2)*( N) + (N+2)*(N+2)*( N+1)] + x[N+1 + (N+2)*( N+1) + (N+2)*(N+2)*( N)]);
  }
  //printf("setbnd corner end\n");
  return;
}

//Draw
void draw_smoke(){
  //printf("In draw smoke\n");
  float scale = .015;
  //float size = .01;
  float x, y, z;
  //glBegin(GL_TRIANGLES);
  glPointSize(10);
  glBegin(GL_POINTS);
  //printf("In draw smoke 2\n");
  //float dtotal = 0;
  //float color = 0;
  for (size_t l = 1; l <= N; l++) {
    for (size_t j = 1; j <= N; j++) {
      for (size_t i = 1; i <= N; i++) {
        //glColor3f(255, 255, 255);
        //printf("In draw smoke 2.1\n");
        //dtotal += dens[IX(i, j, l)];
        //printf("In draw smoke 2.2\n");
        if (dens[IX(i, j, l)]>.05) {
          // printf("In draw smoke 2.3\n");
          // printf("%d, %d, %d: %d\n", i, j, l, IX(i, j, l));
          //color = dens[i + (N+2)*j + (N+2)*(N+2)*l]*5;
          //printf("In draw smoke 2.31\n");
          glColor4f(.8, .8, .8, dens[i + (N+2)*j + (N+2)*(N+2)*l]*.001);
          //printf("In draw smoke 2.4\n");
          x = i * scale;
          y = j * scale;
          z = l * scale;
          //glBegin(GL_TRIANGLES);
          glVertex3f(x, y, z);
          //printf("In draw smoke 2.5\n");
          //glEnd();
        }
      }
    }
  }
  glEnd();
  //printf("leaving draw smoke\n");
  //float davg = dtotal/(N*N*N);

  //printf("d average %f\n", davg);
  //printf("%f\n", dens[IX(10, 10, 10)]);
  //glEnd();
  // glBegin(GL_TRIANGLES);
  // glVertex3d(0,0,0);
  // glVertex3d(0,1,0);
  // glVertex3d(0,1,1);
  // glEnd();
  return;
}

//Run progression and call draw_smoke()
void run_smoke(){
  //TODO mouse press

  //temp Source
  // if(sourceCount < 15){
  //   dens_prev.at(IX(10, 10, 10)) += 100000;
  //   v2_prev.at(IX(10, 10, 10)) += 80000;
  //   v3_prev.at(IX(10, 10, 10)) += 5000;
  //   sourceCount +=1;
  // }
  //printf("in run_smoke\n");
  dens_prev[IX(2, 2, 2)] += 2000;
  v2_prev[IX(2, 2, 2)] += 5000000;
  //v3[IX(30, 10, 30)] = 50000;

  vel_step(v1, v2, v3, v1_prev, v2_prev, v3_prev);
  dens_step(dens, dens_prev, v1, v2, v3);
  //cudaDeviceSynchronize();

  //draw_smoke();

  return;
}

//setup
void setup(){
  printf("IN setup\n");
  size = (N+2)*(N+2)*(N+2);
  printf("size: %d\n", size);

  // v1 = new float[size];
  // v2 = new float[size];
  // v3 = new float[size];
  cudaMallocManaged(&v1, size*sizeof(float));
  cudaMallocManaged(&v2, size*sizeof(float));
  cudaMallocManaged(&v3, size*sizeof(float));

  // v1_prev = new float[size];
  // v2_prev = new float[size];
  // v3_prev = new float[size];
  cudaMallocManaged(&v1_prev, size*sizeof(float));
  cudaMallocManaged(&v2_prev, size*sizeof(float));
  cudaMallocManaged(&v3_prev, size*sizeof(float));

  // dens = new float[size];
  // dens_prev = new float[size];
  cudaMallocManaged(&dens, size*sizeof(float));
  cudaMallocManaged(&dens_prev, size*sizeof(float));
  for (size_t i = 0; i < size; i++) {
    v1[i] = 0.0f;
    v2[i] = 0.0f;
    v3[i] = 0.0f;

    v1_prev[i] = 0.0f;
    v2_prev[i] = 0.0f;
    v3_prev[i] = 0.0f;

    dens[i] = 0.0f;
    dens_prev[i] = 0.0f;

  }
  printf("leaving setup\n");
  return;
}

void cleanup(){
  // delete [] v1;
  // delete [] v2;
  // delete [] v3;
  cudaFree(v1);
  cudaFree(v2);
  cudaFree(v3);

  // delete [] v1_prev;
  // delete [] v2_prev;
  // delete [] v3_prev;
  cudaFree(v1_prev);
  cudaFree(v2_prev);
  cudaFree(v3_prev);

  // delete [] dens;
  // delete [] dens_prev;
  cudaFree(dens);
  cudaFree(dens_prev);

  return;
}
//TODO add K value
