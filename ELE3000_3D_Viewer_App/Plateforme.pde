
class Plateforme
{
  PMatrix3D rotMatrix;
 final float REAL_WEIGHT = 1;
 float pLength, pWidth, pWeight;
 float realLength, realWidth;
 float scaling;
 int wToP_ratio;
 PVector center, planeNormal, angles;
 color pColor;
 int arrowScale = 50;
 Fleche flechesOrientation[];
 
  
  public Plateforme(PVector center, int pLength, int pWidth, int pWeight, int worldRatio)
  {
    this.pLength = pLength;
    this.pWidth = pWidth;
    this.pWeight = pWeight;
    this.wToP_ratio = worldRatio;
    this.center = center;
    this.angles = new PVector(0, 0, 0);
    this.planeNormal = new PVector(0, 1, 0);
    this.pColor = color(255, 255, 255);
    this.scaling = 1;
    rotMatrix = new PMatrix3D();
    rotMatrix.reset();
  }
  
   public Plateforme(PVector center, float wLength, float wWidth, int worldRatio)
  {
    this.realLength = wLength;
    this.realWidth = wWidth;
    this.pLength = wLength * worldRatio;
    this.pWidth = wWidth * worldRatio;
    this.pWeight = REAL_WEIGHT * worldRatio;
    this.wToP_ratio = worldRatio;
    this.center = center;
    this.angles = new PVector(0, 0, 0);
    this.planeNormal = new PVector(0, 1, 0);
    this.pColor = color(255, 255, 255);
    this.scaling = 1;
    rotMatrix = new PMatrix3D();
    flechesOrientation = new Fleche[3];
    flechesOrientation[0] = new Fleche(new PVector(0,0,0), new PVector(250,0,0));
    flechesOrientation[1] = new Fleche(new PVector(0,0,0), new PVector(0,-100,0));
    flechesOrientation[1].setColor(color(0,255,0));
    flechesOrientation[2] = new Fleche(new PVector(0,0,0), new PVector(0,0,175));
    flechesOrientation[2].setColor(color(0,0,255));
    rotMatrix.reset();
  }
    
  public void display()
  {
    pushMatrix();
    translate(this.center.x, this.center.y - this.pWeight/2, this.center.z);
    rotateX(-radians(this.angles.x));
    rotateZ(radians(this.angles.y));
    rotateY(-radians(this.angles.z));
    flechesOrientation[0].display();
    flechesOrientation[1].display();
    flechesOrientation[2].display();
    fill(this.pColor);
    stroke(255, 0, 255);
    box(scaling*this.pLength, this.pWeight,  scaling*this.pWidth);
    popMatrix();
  }
  
  public void displayWithNormal()
  {
    pushMatrix();
    translate(this.center.x, this.center.y - this.pWeight/2, this.center.z);
    stroke(255, 0, 0);
    line(0,0,0,arrowScale*this.planeNormal.x, arrowScale*this.planeNormal.y, arrowScale*this.planeNormal.z);
    //this.planeNormal.x = sqrt(3)/2;
    //this.planeNormal.y = 1;
    //this.planeNormal.z = 1/2;
    //this.angles.x = degrees(atan(this.planeNormal.z/this.planeNormal.y));
    //this.angles.y = degrees(atan(this.planeNormal.x/this.planeNormal.y));
    //rotateX(-radians(this.angles.x));
    //rotateZ(radians(this.angles.y));
    //rotateY(-radians(this.angles.z));
    //fill(this.pColor);
    //box(scaling*this.pLength, this.pWeight,  scaling*this.pWidth);
    //stroke(color(255,60,150));
    //strokeWeight(2);
    //line(0,0,0,0,-arrowScale, 0);
    //line(0,0,0, 200, 0, 0);
    //line(0,0,0, 0,0,150);
    popMatrix();
  }
  
  public void estimatePosOnlyHeightPoints(float height1, float height2, float height3, float height4)
  {
    //-------| INFO |-------//
    // height3 sera utilisee comme reference dans 
    // le calcul des angles du plan
    float alpha = atan((height1 - height3)/18.5);
    float beta = atan((height4 - height3)/13.5);
    PVector y_plan = new PVector(0.0, cos(beta), 0.0);
    PVector x_plan = new PVector(cos(alpha), 0.0, 0.0);
    this.planeNormal = x_plan.cross(y_plan);
    this.angles.x = degrees(beta);
    this.angles.y = -degrees(alpha);
    float h3 = height3 * cos(alpha)*cos(beta);
    this.center.y = -10*(h3 + 18.5/2*sin(alpha) + 13.5/2*sin(beta));
   // println(this.center.y);
  }

  
  public void setAngles(float pitch, float roll, float yaw)
  {
    this.angles.x = pitch;
    this.angles.y = roll;
    this.angles.z = yaw;
    rotMatrix.reset();
    rotMatrix.rotateX(-radians(pitch));
    rotMatrix.rotateZ(radians(roll));
    this.planeNormal.x = rotMatrix.multX(0, -1, 0);
    this.planeNormal.y = rotMatrix.multY(0, -1, 0);
    this.planeNormal.z = rotMatrix.multZ(0, -1, 0);
  }
  
  public void setPosition(int newX, int newY, int newZ)
  {
   this.center.x = newX;
   this.center.y = newY;
   this.center.z = newZ;
  }
  
  public void setPlaneScaling(float scale)
  {
   this.scaling = scale; 
  }
  
  public void setColor(color newColor)
  {
   this.pColor = newColor; 
  }
  
  
}
