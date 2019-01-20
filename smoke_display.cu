/*  Teo Price-Broncucia
 *  HW6
 *
 *  Based on work of Ex9 by Willem A. (Vlakkies) Schreuder. And previous homework 5
 *  by me.
 *
 *  Take a walk among the trees! Since the trees are randomly generated every
 *  walk will different. Now the trees and ground have image textures.
 *
 *  Key bindings:
 *  1, 2, 3    Toggle between orthogonal, perspective, and first person
 *  w, a, s, d Move position in first person
 *  arrows     Change view angle
 // u/j, i/k, o/l change relative red/blue/green
 // m pause light movement
 *  ESC        Exit

 */
// #include <stdio.h>
// #include <stdlib.h>
// #include <stdarg.h>
#include "CSCIx229.h"
#include <math.h>
#include <stdbool.h>
#include <time.h>
#include "smoke.cuh"
//  OpenGL with prototypes for glext
// #define GL_GLEXT_PROTOTYPES
// #ifdef __APPLE__
// #include <GLUT/glut.h>
// #else
// #include <GL/glut.h>
// #endif

int axes=0;       //  Display axes
int mode=2;       //  Projection mode
int th=-30;         //  Horizontal view angle
int ph=30;         //  Elevation of view angle
double Px = 2.0;   // Position of viewer
double Py = 0.2;
double Pz = 2.0;
double di = 0.05; //movement increment
int fov=40;       //  Field of view (for perspective)
double asp=1;     //  Aspect ratio
double dim=2.5;   //  Size of world


int zh        =  90;  // Light azimuth


//  Macro for sin & cos in degrees
#define Cos(th) cos(3.1415926/180*(th))
#define Sin(th) sin(3.1415926/180*(th))


/*
 *  Convenience routine to output raster text
 *  Use VARARGS to make this more flexible
 */
#define LEN 8192  //  Maximum length of text string
void Print(const char* format , ...)
{
   char    buf[LEN];
   char*   ch=buf;
   va_list args;
   //  Turn the parameters into a character string
   va_start(args,format);
   vsnprintf(buf,LEN,format,args);
   va_end(args);
   //  Display the characters one at a time at the current raster position
   while (*ch)
      glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18,*ch++);
}

/*
 *  Set projection
 */
static void Project()
{
   //  Tell OpenGL we want to manipulate the projection matrix
   glMatrixMode(GL_PROJECTION);
   //  Undo previous transformations
   glLoadIdentity();
   //  Perspective transformation
   if (mode == 2 || mode == 3)
      gluPerspective(fov,asp,dim/16,6*dim);
   //  Orthogonal projection
   else
      glOrtho(-asp*dim,+asp*dim, -dim,+dim, -3*dim,+3*dim);
   //  Switch to manipulating the model matrix
   glMatrixMode(GL_MODELVIEW);
   //  Undo previous transformations
   glLoadIdentity();
}



/*
 *  OpenGL (GLUT) calls this routine to display the scene
 */
void display()
{
   const double len=1.5;  //  Length of axes
   //  Erase the window and the depth buffer
   glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
   //  Enable Z-buffering in OpenGL
   glDisable(GL_DEPTH_TEST);

   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA, GL_ONE);
   //  Undo previous transformations
   glLoadIdentity();
   //  Perspective - set eye position
   if (mode==3)
   {
      double Ex = -2*dim*Sin(th)*Cos(ph);
      double Ey = +2*dim        *Sin(ph);
      double Ez = +2*dim*Cos(th)*Cos(ph);
      // gluLookAt(Ex,Ey,Ez , 0,0,0 , 0,Cos(ph),0);
      gluLookAt(Px,Py,Pz , Px + Ex, Py + Ey , Pz + Ez, 0,Cos(ph),0);

   }
   else if (mode == 2)
   {
      double Ex = -2*dim*Sin(th)*Cos(ph);
      double Ey = +2*dim        *Sin(ph);
      double Ez = +2*dim*Cos(th)*Cos(ph);
      gluLookAt(Ex,Ey,Ez , 0,0,0 , 0,Cos(ph),0);

   }
   //  Orthogonal - set world orientation
   else
   {
      glRotatef(ph,1,0,0);
      glRotatef(th,0,1,0);
   }
   //  Flat or smooth shading

    // if(zh == 0){
    //  run_smoke();
    // }
   draw_smoke();

   //  Draw axes
   glDisable(GL_LIGHTING);
   glDisable(GL_TEXTURE_2D);
   glColor3f(1,1,1);
   if (mode == 1 || mode == 2)
   {
      glBegin(GL_LINES);
      glVertex3d(0.0,0.0,0.0);
      glVertex3d(len,0.0,0.0);
      glVertex3d(0.0,0.0,0.0);
      glVertex3d(0.0,len,0.0);
      glVertex3d(0.0,0.0,0.0);
      glVertex3d(0.0,0.0,len);
      glEnd();
      //  Label axes
      glRasterPos3d(len,0.0,0.0);
      Print("X");
      glRasterPos3d(0.0,len,0.0);
      Print("Y");
      glRasterPos3d(0.0,0.0,len);
      Print("Z");
   }
   //  Display parameters
   glWindowPos2i(5,5);
   //Print("Angle=%d,%d Px=%.1f, Pz=%.1f ",th,ph, Px, Pz);
   if (mode == 1) {
     Print("Orthogonal ");
   }
   else if (mode == 2) {
     Print("Perspective ");
   }
   else if (mode == 3) {
     Print("First Person ");
   }
   //  Render the scene and make it visible
   glFlush();
   glutSwapBuffers();
}

/*
 *  GLUT calls this routine when the window is resized
 */
void idle()
{
   //printf("in idle\n");
   //  Elapsed time in seconds
   double t = glutGet(GLUT_ELAPSED_TIME)/1000.0;
   zh = fmod(90*t,360.0);
   run_smoke();
   //  Tell GLUT it is necessary to redisplay the scene
   glutPostRedisplay();
}

/*
 *  GLUT calls this routine when an arrow key is pressed
 */
void special(int key,int x,int y)
{
   //  Right arrow key - increase angle by 5 degrees
   if (key == GLUT_KEY_RIGHT)
      th += 5;
   //  Left arrow key - decrease angle by 5 degrees
   else if (key == GLUT_KEY_LEFT)
      th -= 5;
   //  Up arrow key - increase elevation by 5 degrees
   else if (key == GLUT_KEY_UP)
      ph += 5;
   //  Down arrow key - decrease elevation by 5 degrees
   else if (key == GLUT_KEY_DOWN)
      ph -= 5;
   //  PageUp key - increase dim
   else if (key == GLUT_KEY_PAGE_UP)
      dim += 0.1;
   //  PageDown key - decrease dim
   else if (key == GLUT_KEY_PAGE_DOWN && dim>1)
      dim -= 0.1;
   //  Keep angles to +/-360 degrees
   th %= 360;
   ph %= 360;
   //  Update projection
   Project();
   //  Tell GLUT it is necessary to redisplay the scene
   glutPostRedisplay();
}

/*
 *  GLUT calls this routine when a key is pressed
 */
void key(unsigned char ch,int x,int y)
{
   //  Exit on ESC
   if (ch == 27)
      exit(0);
   //  Reset view angle
   else if (ch == '0')
      th = ph = 0;
   //  Switch display mode
   else if (ch == '1')
      mode = 1;
   else if (ch == '2')
      mode = 2;
   else if (ch == '3')
      mode = 3;
   //  Change field of view angle
   else if (ch == '-' && ch>1)
      fov--;
   else if (ch == '+' && ch<179)
      fov++;
   // For movement
   else if (ch == 'd'){
      Px = Px - di * Cos(th);
      Pz = Pz - di * Sin(th);
   }
   else if (ch == 's'){
     dens_prev[IX(10, 10, 10)] += 50000;
     v2_prev[IX(10, 10, 10)] += 10000;
   }
   else if (ch == 'a'){
      Px = Px + di * Cos(th);
      Pz = Pz + di * Sin(th);
    }
   else if (ch == 'w'){
      Px = Px - di * Sin(th);
      Pz = Pz + di * Cos(th);
    }
   //  Reproject
   Project();
   //  Animate if requested
   //  Tell GLUT it is necessary to redisplay the scene
   glutPostRedisplay();
}

/*
 *  GLUT calls this routine when the window is resized
 */
void reshape(int width,int height)
{
   //  Ratio of the width to the height of the window
   asp = (height>0) ? (double)width/height : 1;
   //  Set the viewport to the entire window
   glViewport(0,0, width,height);
   //  Set projection
   Project();
}

/*
 *  Start up GLUT and tell it what to do
 */
int main(int argc,char* argv[])
{


  setup();
   //  Initialize GLUT
   glutInit(&argc,argv);
   //  Request double buffered, true color window with Z buffering at 600x600
   glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE);
   glutInitWindowSize(600,600);
   glutCreateWindow("Teo Price-Broncucia");
   //  Set callbacks
   glutDisplayFunc(display);
   glutReshapeFunc(reshape);
   glutSpecialFunc(special);
   glutKeyboardFunc(key);
   glutIdleFunc(idle);
   //  Pass control to GLUT so it can interact with the user
   glutMainLoop();

   cleanup();
   return 0;
}
