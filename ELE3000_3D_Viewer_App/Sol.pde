class Sol
{
  final int MIN_DIST_QUAD_LINE = 20; //In pixels
  final float DEFAULT_QUAD_DENSITY = 0.5;
  final color DEFAULT_COLOR = color(0, 255, 0);
  
  int size;
  color pColor;
  float quadDensity;
  
  public Sol(int size)
  {
   this.size = size; 
   pColor = color(DEFAULT_COLOR);
   quadDensity = DEFAULT_QUAD_DENSITY;
  }
  
  public void display()
  {
   pushMatrix();
   translate(- this.size/2, 0, this.size/2);
   int numLines = ceil(quadDensity*size/MIN_DIST_QUAD_LINE) + 1;
   float stepSize = size*1.0/(numLines-1);
   stroke(pColor);
   for (int i=0; i<numLines; i++)
   {
     line(stepSize*i, 0, 0, stepSize*i, 0, -size);
     line(0, 0, -stepSize*i, size, 0, -stepSize*i);
   }
   popMatrix();
  }

}
