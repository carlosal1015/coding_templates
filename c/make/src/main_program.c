/*
 * Contains main program.
 */

#include <stdio.h> /* input, output    */

#include "commons.h"
#include "init.h"

int main(int argc, char* argv[]) {

  initialise(argc, argv);

  printf("\nNx : %d \nNy : %d  \ndx : %f  \ndy : %f \n", Nx, Ny, dx, dy);
  return (0);
}
