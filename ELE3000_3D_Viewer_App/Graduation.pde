class Graduation
{
  float realLength;
  float pixelLength;
  float wToP_ratio;
  float deltaGrad;
  float tickSize;
  PVector beginPoint, dir, rotAxis;
  color axisColor, tickColor;
  boolean limitCase;
  
  public Graduation(PVector pos, PVector dir, float wToP_ratio, float realLength, float deltaGrad)
  {
     this.realLength =  realLength;
     this.wToP_ratio = wToP_ratio;
     this.beginPoint = pos;
     this.dir = dir;
     this.deltaGrad = deltaGrad;
     this.pixelLength = wToP_ratio * realLength;
     if (this.dir.x < 0 && this.dir.y == 0 && this.dir.z == 0) this.limitCase = true;
    else this.limitCase = false;
    this.rotAxis = this.dir.cross(new PVector(1, 0, 0));
     this.axisColor = color(175,238,238);
     this.tickColor = color(255,0,0);
     this.tickSize = 5;
  }
  
  public void display()
  {
    pushMatrix();
    translate(this.beginPoint.x, this.beginPoint.y, this.beginPoint.z);
   if (this.limitCase) rotateY(PI);
   else rotate(-PVector.angleBetween(new PVector(1,0,0), this.dir), this.rotAxis.x, this.rotAxis.y, this.rotAxis.z);
    int nbTicks = floor(realLength/deltaGrad) + 1;
    strokeWeight(2);
    stroke(axisColor);
    line(0, 0, 0, pixelLength, 0, 0);
    fill(this.tickColor);
    stroke(this.tickColor);
    strokeWeight(1);
    for (int i=0; i<nbTicks; i++)
    {
      box(2, tickSize, tickSize);
      //sphere(3);
      translate(deltaGrad*wToP_ratio, 0, 0);
    }
    popMatrix();
  }
  
  public void setColor(color newAxisColor, color newTickColor)
  {
   this.axisColor = newAxisColor;
   this.tickColor = newTickColor;
  }
  
  public void setGraduationDelta(float newDelta)
  {
   this.deltaGrad = newDelta; 
  }
  
  public void setPos(PVector newPos)
  {
   this.beginPoint = newPos; 
  }
  
  public void setPixelLength(float newPixelLength)
  {
   this.pixelLength =  newPixelLength;
   this.realLength = newPixelLength / this.wToP_ratio;
  }
  
}
