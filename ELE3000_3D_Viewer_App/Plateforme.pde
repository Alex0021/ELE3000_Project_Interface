
class Plateforme
{
  PMatrix3D rotMatrix;
 final float REAL_WEIGHT = 1;
 final float TICK_RESOLUTION = 2.5; //En cm
 float pLength, pWidth, pWeight;
 float realLength, realWidth;
 float scaling;
 int wToP_ratio;
 PVector center, planeNormal, angles;
 color pColor;
 int arrowScale = 50;
 Fleche flechesOrientation[];
 Graduation echellesGrad[];
 
  
  public Plateforme(PVector center, int pLength, int pWidth, int pWeight, int worldRatio, float realLength, float realWidth)
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
    this.realLength = realLength;
    this.realWidth = realWidth;
    rotMatrix = new PMatrix3D();
    rotMatrix.reset();
  }
  
   public Plateforme(PVector center, float wLength, float wWidth, int worldRatio, float realLength, float realWidth)
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
    this.realLength = realLength;
    this.realWidth = realWidth;
    rotMatrix = new PMatrix3D();
    flechesOrientation = new Fleche[3];
    flechesOrientation[0] = new Fleche(new PVector(0,0,0), new PVector(250,0,0));
    flechesOrientation[1] = new Fleche(new PVector(0,0,0), new PVector(0,-100,0));
    flechesOrientation[1].setColor(color(0,255,0));
    flechesOrientation[2] = new Fleche(new PVector(0,0,0), new PVector(0,0,175));
    flechesOrientation[2].setColor(color(0,0,255));
    echellesGrad = new Graduation[5];
    for (int i=0; i<5; i++) 
    {
      echellesGrad[i] = new Graduation(new PVector(0,0,0), new PVector(0, -1, 0), this.wToP_ratio, 10, TICK_RESOLUTION);
    }
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
    echellesGrad[0].setPos(new PVector(this.center.x, 0, this.center.z));
    echellesGrad[0].setPixelLength(abs(this.center.y));
    echellesGrad[0].display();
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
    float center[] = new float[4];
    float alpha[] = new float[4];
    float beta[] = new float[4];
    // height3 sera utilisee comme reference dans 
    // le calcul des angles du plan
    alpha[0] = atan((height1 - height3)/this.realLength);
    beta[0] = atan((height4 - height3)/this.realWidth);

    float h3 = height3 * cos(alpha[0])*cos(beta[0]);
    center[0] = -wToP_ratio*(h3 + this.realLength/2*sin(alpha[0]) + this.realWidth/2*sin(beta[0]));
    //this.center.y = -10*(h3 + 18.5/2*sin(alpha) + 13.5/2*sin(beta));
    
    //Calcul des 3 autres possibilites pour faire une moyenne
    // height2 comme reference
    alpha[1] = atan((height4 - height2)/this.realLength);
    beta[1] = atan((height1 - height2)/this.realWidth);
    float h2 = height2 * cos(alpha[1])*cos(beta[1]);
    center[1] = -wToP_ratio*(h2 + this.realLength/2*sin(alpha[1]) + this.realWidth/2*sin(beta[1]));
    // height1 comme reference
    alpha[2] = atan((height3 - height1)/this.realLength);
    beta[2] = atan((height2 - height1)/this.realWidth);
    float h1 = height1 * cos(alpha[2])*cos(beta[2]);
    center[2] = -wToP_ratio*(h1 + this.realLength/2*sin(alpha[2]) + this.realWidth/2*sin(beta[2]));
    // height4 comme reference
    alpha[3] = atan((height2 - height4)/this.realLength);
    beta[3] = atan((height3 - height4)/this.realWidth);
    float h4 = height4 * cos(alpha[3])*cos(beta[3]);
    center[3] = -wToP_ratio*(h4 + this.realLength/2*sin(alpha[3]) + this.realWidth/2*sin(beta[3]));
    
    //Calcul des valeurs moyennes
    float betaMean = 0, alphaMean = 0, centerMean = 0;
    for (int i=0; i<center.length; i++)
    {
      centerMean += center[i];
      alphaMean += abs(alpha[i]);
      betaMean += abs(beta[i]);
    }
    centerMean /= center.length;
    betaMean /= beta.length;
    if (beta[0] < 0) betaMean *= -1;
    alphaMean /= alpha.length;
    if (alpha[0] < 0) alphaMean *= -1;
    PVector y_plan = new PVector(0.0, cos(betaMean), 0.0);
    PVector x_plan = new PVector(cos(alphaMean), 0.0, 0.0);
    this.planeNormal = x_plan.cross(y_plan);
    this.angles.x = degrees(betaMean);
    this.angles.y = -degrees(alphaMean);
    this.center.y = centerMean;
    println(center[0] + " | " + center[1] + " | " + center[2] + " | " + center[3]);
    
   // println(this.center.y);
  }

  public void estimatePosHeightAndIMU(float heights[], float pitch, float roll)
  {
    //-------| INFO |-------//
    float center[] = new float[4];
    //Calcul des 4 hauteurs possibles pour effectuer la moyenne
    // height1 comme reference
    float h1 = heights[0] * cos(roll)*cos(pitch);
    center[0] = -wToP_ratio*(h1 + this.realLength/2*sin(roll) + this.realWidth/2*sin(pitch));
    // height2 comme reference
    float h2 = heights[1] * cos(roll)*cos(pitch);
    center[1] = -wToP_ratio*(h2 + this.realLength/2*sin(roll) + this.realWidth/2*sin(pitch));
    //height3 comme reference
    float h3 = heights[2] * cos(roll)*cos(pitch);
    center[2] = -wToP_ratio*(h3 + this.realLength/2*sin(roll) + this.realWidth/2*sin(pitch));
    // height4 comme reference
    float h4 = heights[3] * cos(roll)*cos(pitch);
    center[3] = -wToP_ratio*(h4 + this.realLength/2*sin(roll) + this.realWidth/2*sin(pitch));
    
    //Calcul des valeurs moyennes
    float centerMean = 0;
    for (int i=0; i<center.length; i++)
    {
      centerMean += center[i];
    }
    centerMean /= center.length;
    PVector y_plan = new PVector(0.0, cos(pitch), 0.0);
    PVector x_plan = new PVector(cos(roll), 0.0, 0.0);
    this.planeNormal = x_plan.cross(y_plan);
    this.angles.x = degrees(pitch);
    this.angles.y = degrees(roll);
    this.center.y = centerMean;
        println(center[0] + " | " + center[1] + " | " + center[2] + " | " + center[3]);
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
