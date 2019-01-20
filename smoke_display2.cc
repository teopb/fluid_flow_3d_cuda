#include "CSCIx229.h"
#include <math.h>
#include <stdbool.h>
#include <time.h>
#include "smoke.h"

double asp=1;     //  Aspect ratio
double dim=1.0;   //  Size of world

int th=0;       // Azimuth of view angle
int ph=0;       // Elevation of view angle
double z=0;     // Z variable
double w=1;     // W variable

void display()
{
  //  Length of axes
   const double len=2.0;
   //  Erase the window and the depth buffer
   glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
   //  Enable Z-buffering in OpenGL
   glEnable(GL_DEPTH_TEST);

   glRotated(ph,1,0,0);
   glRotated(th,0,1,0);
   //  Undo previous transformations
   glLoadIdentity();

   //draw_smoke();

   //  Draw axes
   glDisable(GL_LIGHTING);
   glDisable(GL_TEXTURE_2D);
   glColor3f(1,1,1);
   //Axis
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

   //  Render the scene and make it visible
   glFlush();
   glutSwapBuffers();
}

void idle()
{
   //  Elapsed time in seconds
   double t = glutGet(GLUT_ELAPSED_TIME)/1000.0;
   //  Tell GLUT it is necessary to redisplay the scene
   run_smoke();
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
   Project(60, asp, dim);
}

/*
 *  Start up GLUT and tell it what to do
 */
int main(int argc,char* argv[])
{
   //smoke setup
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
   glutIdleFunc(idle);
   //  Pass control to GLUT so it can interact with the user
   glutMainLoop();
   return 0;
}
