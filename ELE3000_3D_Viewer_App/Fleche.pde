class Fleche
{
  final int ARROW_HEAD_LENGTH = 40;
  final int ARROW_HEAD_WIDTH = 15;
 PVector pos, dir, rotAxis;
 boolean limitCase;
 color pColor;
 
 
 public Fleche(PVector point1, PVector  point2)
 {
  this.pos = new PVector(point1.x, point1.y, point1.z);
  this.dir = PVector.sub(point2, point1);
  if (this.dir.x < 0 && this.dir.y == 0 && this.dir.z == 0) this.limitCase = true;
  else this.limitCase = false;
  this.rotAxis = this.dir.cross(new PVector(1, 0, 0));
  this.pColor = color(255, 0, 0);
 }
 
 public void display()
 {
   pushMatrix();
   translate(this.pos.x, this.pos.y, this.pos.z);
   if (this.limitCase) rotateY(PI);
   else rotate(-PVector.angleBetween(new PVector(1,0,0), this.dir), this.rotAxis.x, this.rotAxis.y, this.rotAxis.z);
   stroke(pColor);
   strokeWeight(2);
   line(0,0,0,this.dir.mag() - ARROW_HEAD_LENGTH, 0, 0);
   fill(pColor, 150);
  beginShape();
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, ARROW_HEAD_WIDTH/2, ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, -ARROW_HEAD_WIDTH/2, ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, -ARROW_HEAD_WIDTH/2, -ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, ARROW_HEAD_WIDTH/2, -ARROW_HEAD_WIDTH/2);
   endShape(CLOSE);
   beginShape();
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, ARROW_HEAD_WIDTH/2, ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, -ARROW_HEAD_WIDTH/2, ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag(),0,0);
   endShape(CLOSE);
   beginShape();
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, -ARROW_HEAD_WIDTH/2, ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, -ARROW_HEAD_WIDTH/2, -ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag(),0,0);
   endShape(CLOSE);
   beginShape();
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, -ARROW_HEAD_WIDTH/2, -ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, ARROW_HEAD_WIDTH/2, -ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag(),0,0);
   endShape(CLOSE);
   beginShape();
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, ARROW_HEAD_WIDTH/2, -ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag() - ARROW_HEAD_LENGTH, ARROW_HEAD_WIDTH/2, ARROW_HEAD_WIDTH/2);
   vertex(this.dir.mag(),0,0);
   endShape(CLOSE);
   popMatrix();
 }
 
 public void setColor(color newColor)
 {
   this.pColor = newColor;
 }
 
 
  
}
