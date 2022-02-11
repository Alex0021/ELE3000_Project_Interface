import processing.serial.*;
import grafica.*;

//---------------------------------//
//-----------| CONSTANTS |---------//
//---------------------------------//
final int MAX_RXDATA_LENGTH = 24;
final int MAX_HEIGHT_SENOSR_VALUE = 50;
final int MAX_GYRO_VALUE = 250;
final int MAX_ACCEL_VALUE = 2;
final int MAX_TEMP_VALUE = 100;
final float H_PLOT_X_LIM = 10;
final float IMU_PLOT_X_LIM = 10;

final int[] RECORD_BTN_POS = {840, 80};
final int[] RECORD_BTN_DIM = {150, 40};

final int[] SAVE_BTN_POS = {1000, 80};
final int[] SAVE_BTN_DIM = {150, 40};

final int[] IMU_SWITCH_BTN_POS = {840, 130};
final int[] IMU_SWITCH_BTN_DIM = {150, 40};

final String DATAPOINTS_FILENAME = "Data_10_cm_5.txt";

//---------------------------------//
//-------| USER VARIABLES |--------//
//---------------------------------//
// Data processing //
Serial myPort;
byte[] rxBuffer;
float[] rawHeights;
float[] rawGyro;
float[] rawAccel;
float temperature;
int nbRx;

// Graphics //
PFont appFont;

// Data plotting //
GPlot heightPlot;
GPlot imuPlot;
GPointsArray gyroPoints[];
GPointsArray accelPoints[];
float currentTimePoint;
float hPlotXOffset;
long lastTimeStep;

// Application flow //
boolean recordData;
boolean mouseOverRecBtn;
boolean showSaveBtn;
boolean mouseOverSaveBtn;
boolean showGyroPlotData;
boolean mouseOverImuSwitchBtn;
long lastValueTextUpdate;

// Output //
PrintWriter fileOutputStream;

/**
* Setup function :: Called only once when app is launched
*/
void setup()
{
  //Canvas setup
  size(1200, 950);
  frameRate(60);
  
  //Variables initialization
  rxBuffer = new byte[40];
  rawHeights = new float[4];
  rawGyro = new float[3];
  rawAccel = new float[3];
  temperature = 0;
  lastTimeStep = 0;
  currentTimePoint = 0;
  hPlotXOffset = 0;
  lastValueTextUpdate = 0;
  recordData = false;
  mouseOverRecBtn = false;
  showSaveBtn = false;
  showGyroPlotData = true;
  mouseOverImuSwitchBtn = false;
  appFont = loadFont("AgencyFB-Bold-48.vlw");  //This font has been previously created using "Create font..." in processing
  
  //Plot setup
  heightPlot = new GPlot(this, 10, 180, width - 20, 350);
  heightPlot.setTitleText("Hauteur aux 4 coins");
  heightPlot.getXAxis().setAxisLabelText("Time (s)");
  heightPlot.getYAxis().setAxisLabelText("Height (cm)");
  heightPlot.activatePanning();
  heightPlot.setXLim(0, H_PLOT_X_LIM);
  heightPlot.setYLim(0, 30);
  heightPlot.getXAxis().setNTicks(20);
  heightPlot.getMainLayer().setLineColor(color(255, 0, 0));
  heightPlot.addLayer("Sensor2", new GPointsArray(100));
  heightPlot.getLayer("Sensor2").setLineColor(color(0, 0, 255));
  heightPlot.addLayer("Sensor3", new GPointsArray(100));
  heightPlot.getLayer("Sensor3").setLineColor(color(0, 255, 0));
  heightPlot.addLayer("Sensor4", new GPointsArray(100));
  heightPlot.getLayer("Sensor4").setLineColor(color(255, 0, 255));
  
  gyroPoints = new GPointsArray[3];
  accelPoints = new GPointsArray[3];
  gyroPoints[0] = new GPointsArray();
  gyroPoints[1] = new GPointsArray();
  gyroPoints[2] = new GPointsArray();
  accelPoints[0] = new GPointsArray();
  accelPoints[1] = new GPointsArray();
  accelPoints[2] = new GPointsArray();
  
  imuPlot = new GPlot(this, 10, 550, width - 20, 350);
  imuPlot.getXAxis().setAxisLabelText("Time (s)");
  imuPlot.setYLim(-100, 100);
  imuPlot.addLayer("Y", gyroPoints[1]);
  imuPlot.addLayer("Z", gyroPoints[2]);
  imuPlot.getMainLayer().setLineColor(color(255, 0, 0));
  imuPlot.getLayer("Y").setLineColor(color(0, 255, 0));
  imuPlot.getLayer("Z").setLineColor(color(0, 0, 255));
  imuPlot.getXAxis().setNTicks(20);
  imuPlot.setXLim(0, IMU_PLOT_X_LIM);
  imuPlot.activatePanning();
  setGyroDataImuPlot(showGyroPlotData);
  
  //Serial connection
  printArray(Serial.list());
  try {
    myPort = new Serial(this, Serial.list()[0], 115200);
  } catch (Exception e) {
    println(e);
  }
}

void draw()
{
  background(0);
  
  //Checking serial buffer
  if (myPort.available() >= MAX_RXDATA_LENGTH)  //All values have been received
  {
    myPort.readBytes(rxBuffer);
    processRxData();
  }
  
  // Draw text //
  textFont(appFont);
  textSize(32);
  stroke(255);
  strokeWeight(2);
  fill(255);
  text("#4:   " + round(rawHeights[3]*100)/100.0, 10, 50);
  text("#3:   " + round(rawHeights[2]*100)/100.0, 10, 150);
  line(150, 0, 150, 175);
  text("#2:   " + round(rawHeights[1]*100)/100.0, 175, 50);
  text("#1:   " + round(rawHeights[0]*100)/100.0, 175, 150);
  line(0, 87.5, 300, 87.5);
  text("Gyro X:   " + round(rawGyro[0]*1000)/1000.0, 350, 50);
  text("Gyro Y:   " + round(rawGyro[1]*1000)/1000.0, 350, 100);
  text("Gyro Z:   " + round(rawGyro[2]*1000)/1000.0, 350, 150);
  text("Accel X:   " + round(rawAccel[0]*1000)/1000.0, 600, 50);
  text("Accel Y:   " + round(rawAccel[1]*1000)/1000.0, 600, 100);
  text("Accel Z:   " + round(rawAccel[2]*1000)/1000.0, 600, 150);
  text("Temperature:   " + round(temperature*100)/100.0, 850, 50);
    
  // Draw button for starting & stoping data plotting //
  rectMode(CORNER);
  if (mouseOverRecBtn & !recordData)  { fill(color(0, 255, 0, 127)); }
  else if (mouseOverRecBtn & recordData)  { fill(color(255, 0, 0, 127)); }
  else { noFill(); }
  rect(RECORD_BTN_POS[0], RECORD_BTN_POS[1], RECORD_BTN_DIM[0], RECORD_BTN_DIM[1]);
   textSize(22);
  if (recordData) 
  { 
     fill(color(0, 255, 0));
     text("Stop Record", RECORD_BTN_POS[0] + 30, RECORD_BTN_POS[1] + 27);
  }
  else 
  { 
    fill(255);
    text("Start Record", RECORD_BTN_POS[0] + 30, RECORD_BTN_POS[1] + 27);
  }
  
  // Draw save button //
  if (showSaveBtn)
  {
   stroke(255);
   if (mouseOverSaveBtn) {fill(color(127, 127, 127, 127)); }
   else { noFill(); }
   rect(SAVE_BTN_POS[0], SAVE_BTN_POS[1], SAVE_BTN_DIM[0], SAVE_BTN_DIM[1]);
   fill(255);
   textSize(22);
   text("Save Data", SAVE_BTN_POS[0] + 30, SAVE_BTN_POS[1] + 27);
  }
  
  // Draw Gyro <--> Accel Values button //
   stroke(255);
   if (mouseOverImuSwitchBtn) {fill(color(127, 127, 127, 127)); }
   else { noFill(); }
   rect(IMU_SWITCH_BTN_POS[0], IMU_SWITCH_BTN_POS[1], IMU_SWITCH_BTN_DIM[0], IMU_SWITCH_BTN_DIM[1]);
   fill(255);
   textSize(22);
   if (showGyroPlotData) { text("Switch to Accel", IMU_SWITCH_BTN_POS[0] + 20, IMU_SWITCH_BTN_POS[1] + 27); }
   else { text("Switch to Gyro", IMU_SWITCH_BTN_POS[0] + 20, IMU_SWITCH_BTN_POS[1] + 27);}
   
  // Draw plots //
  heightPlot.beginDraw();
  heightPlot.drawBackground();
  heightPlot.drawBox();
  heightPlot.drawGridLines(GPlot.BOTH);
  heightPlot.drawXAxis();
  heightPlot.drawYAxis();
  heightPlot.drawTopAxis();
  heightPlot.drawRightAxis();
  heightPlot.drawTitle();
  heightPlot.getMainLayer().drawLines();
  heightPlot.getLayer("Sensor2").drawLines();
  heightPlot.getLayer("Sensor3").drawLines();
  heightPlot.getLayer("Sensor4").drawLines();
  heightPlot.drawLegend(new String[] {"Hauteur 1", "Hauteur 2", "Hauteur 3", "Hauteur 4"}, new float[] {0.04, 0.04, 0.14, 0.14}, new float[] {0.92, 0.86, 0.92, 0.86});
  heightPlot.endDraw();
  
  imuPlot.beginDraw();
  imuPlot.drawBackground();
  imuPlot.drawBox();
  imuPlot.drawGridLines(GPlot.BOTH);
  imuPlot.drawXAxis();
  imuPlot.drawYAxis();
  imuPlot.drawTopAxis();
  imuPlot.drawRightAxis();
  imuPlot.drawTitle();
  imuPlot.getMainLayer().drawLines();
  imuPlot.getLayer("Y").drawLines();
  imuPlot.getLayer("Z").drawLines();
  if (showGyroPlotData) { imuPlot.drawLegend(new String[] {"Gyro X", "Gyro Y", "Gyro Z"}, new float[] {0.04, 0.1, 0.16}, new float[] {0.92, 0.92, 0.92}); }
  else { imuPlot.drawLegend(new String[] {"Accel X", "Accel Y", "Accel Z"}, new float[] {0.04, 0.1, 0.16}, new float[] {0.92, 0.92, 0.92}); }
  imuPlot.endDraw();
  
  // Update plot data //
  if (recordData)
  {
    if (millis() - lastTimeStep > 33 || lastTimeStep == 0)
    {
      if (currentTimePoint- heightPlot.getXLim()[0] > H_PLOT_X_LIM)
      {
       heightPlot.setXLim(heightPlot.getXLim()[1], heightPlot.getXLim()[1]  + H_PLOT_X_LIM);
      }
      if (currentTimePoint - imuPlot.getXLim()[0] > IMU_PLOT_X_LIM)
      {
       imuPlot.setXLim(imuPlot.getXLim()[1], imuPlot.getXLim()[1]  + IMU_PLOT_X_LIM);
      }
      //Update Gyro Points
      gyroPoints[0].add(new GPoint(currentTimePoint, rawGyro[0]));
      gyroPoints[1].add(new GPoint(currentTimePoint, rawGyro[1]));
      gyroPoints[2].add(new GPoint(currentTimePoint, rawGyro[2]));
      
      //Update Accel Points
      accelPoints[0].add(new GPoint(currentTimePoint, rawAccel[0]));
      accelPoints[1].add(new GPoint(currentTimePoint, rawAccel[1]));
      accelPoints[2].add(new GPoint(currentTimePoint, rawAccel[2]));
      
      if (showGyroPlotData)
      {
        imuPlot.getMainLayer().setPoints(gyroPoints[0]);
        imuPlot.getLayer("Y").setPoints(gyroPoints[1]);
        imuPlot.getLayer("Z").setPoints(gyroPoints[2]);
      }
      else
      {
        imuPlot.getMainLayer().setPoints(accelPoints[0]);
        imuPlot.getLayer("Y").setPoints(accelPoints[1]);
        imuPlot.getLayer("Z").setPoints(accelPoints[2]);
      }
      
      //Update Height points
      heightPlot.addPoint(new GPoint(currentTimePoint, rawHeights[0]));
      heightPlot.getLayer("Sensor2").addPoint(new GPoint(currentTimePoint, rawHeights[1]));
      heightPlot.getLayer("Sensor3").addPoint(new GPoint(currentTimePoint, rawHeights[2]));
      heightPlot.getLayer("Sensor4").addPoint(new GPoint(currentTimePoint, rawHeights[3]));
      
      //Update step count
      currentTimePoint += 0.033;
     lastTimeStep = millis(); 
    }
  }
   
// !! TEMPORARY DELAY !!//

}

void mouseMoved()
{
  mouseOverRecBtn = false;
  mouseOverSaveBtn = false;
  mouseOverImuSwitchBtn = false;
  if (mouseX > RECORD_BTN_POS[0] && mouseX < RECORD_BTN_POS[0] + RECORD_BTN_DIM[0])
  {
   if (mouseY >  RECORD_BTN_POS[1] && mouseY < RECORD_BTN_POS[1] + RECORD_BTN_DIM[1])
   {
      mouseOverRecBtn = true;
      return;
   }
  }
  if (mouseX > SAVE_BTN_POS[0] && mouseX < SAVE_BTN_POS[0] + SAVE_BTN_DIM[0])
  {
   if (mouseY >  SAVE_BTN_POS[1] && mouseY < SAVE_BTN_POS[1] + SAVE_BTN_DIM[1])
   {
      mouseOverSaveBtn = true;
      return;
   }
  }
  if (mouseX > IMU_SWITCH_BTN_POS[0] && mouseX < IMU_SWITCH_BTN_POS[0] + IMU_SWITCH_BTN_DIM[0])
  {
   if (mouseY >  IMU_SWITCH_BTN_POS[1] && mouseY < IMU_SWITCH_BTN_POS[1] + IMU_SWITCH_BTN_DIM[1])
   {
      mouseOverImuSwitchBtn = true;
      return;
   }
  }
}

void mouseClicked()
{
  if (mouseX > RECORD_BTN_POS[0] && mouseX < RECORD_BTN_POS[0] + RECORD_BTN_DIM[0])
  {
   if (mouseY >  RECORD_BTN_POS[1] && mouseY < RECORD_BTN_POS[1] + RECORD_BTN_DIM[1])
   {
     if (!recordData)
     {
       //Reset plot data points
       heightPlot.getMainLayer().setPoints(new GPointsArray(100));
       heightPlot.getLayer("Sensor2").setPoints(new GPointsArray(100));
       heightPlot.getLayer("Sensor3").setPoints(new GPointsArray(100));
       heightPlot.getLayer("Sensor4").setPoints(new GPointsArray(100));
       gyroPoints[0] = new GPointsArray();
       gyroPoints[1] = new GPointsArray();
       gyroPoints[2] = new GPointsArray();
       accelPoints[0] = new GPointsArray();
       accelPoints[1] = new GPointsArray();
       accelPoints[2] = new GPointsArray();
       heightPlot.setXLim(0, H_PLOT_X_LIM);
       currentTimePoint = 0;
       recordData = true;
       showSaveBtn = false;
     }
     else
     {
       recordData = false;
       showSaveBtn = true;
     }
   }
  }
  if (mouseX > SAVE_BTN_POS[0] && mouseX < SAVE_BTN_POS[0] + SAVE_BTN_DIM[0])
  {
   if (mouseY >  SAVE_BTN_POS[1] && mouseY < SAVE_BTN_POS[1] + SAVE_BTN_DIM[1])
   {
     if (showSaveBtn)
     {
       saveDataPointsToFile();
     }
   }
  }
  if (mouseX > IMU_SWITCH_BTN_POS[0] && mouseX < IMU_SWITCH_BTN_POS[0] + IMU_SWITCH_BTN_DIM[0])
  {
   if (mouseY >  IMU_SWITCH_BTN_POS[1] && mouseY < IMU_SWITCH_BTN_POS[1] + IMU_SWITCH_BTN_DIM[1])
   {
      showGyroPlotData = !showGyroPlotData;
     setGyroDataImuPlot(showGyroPlotData);
   }
  }
}

void processRxData()
{
  if (rxBuffer[0] != '$')
  {
    println("Serial reception ERROR");
    myPort.clear();
    return;
  }
  // Values conversion //
  int rawVal;
  int sign;
  // Height_1 //
  rawVal = (int(rxBuffer[1]) << 8) | int(rxBuffer[2]);
  rawHeights[0] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
  // Height_2 //
  rawVal = (int(rxBuffer[3]) << 8) | int(rxBuffer[4]);
  rawHeights[1] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
  // Height_3 //
  rawVal = (int(rxBuffer[5]) << 8) | int(rxBuffer[6]);
  rawHeights[2] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
  // Height_4 //
  rawVal = (int(rxBuffer[7]) << 8) | int(rxBuffer[8]);
  rawHeights[3] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
  // GyroX //
  sign = (int(rxBuffer[9] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[9]) << 8) & 0x7F00) | int(rxBuffer[10]);
  rawGyro[0] = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_GYRO_VALUE;
  // GyroY //
  sign = (int(rxBuffer[11] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[11]) << 8) & 0x7F00) | int(rxBuffer[12]);
  rawGyro[1] = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_GYRO_VALUE;
  // GyroZ //
  sign = (int(rxBuffer[13] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[13]) << 8) & 0x7F00) | int(rxBuffer[14]);
  rawGyro[2] = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_GYRO_VALUE;
  // AccelX //
  sign = (int(rxBuffer[15] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[15]) << 8) & 0x7F00) | int(rxBuffer[16]);
  rawAccel[0] = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_ACCEL_VALUE;
  // AccelY //
  sign = (int(rxBuffer[17] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[17]) << 8) & 0x7F00) | int(rxBuffer[18]);
  rawAccel[1] = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_ACCEL_VALUE;
  // AccelZ //
  sign = (int(rxBuffer[19] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[19]) << 8) & 0x7F00) | int(rxBuffer[20]);
  rawAccel[2] = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_ACCEL_VALUE;
  // Temperature //
  sign = (int(rxBuffer[21] >> 7) & 0x01) == 1 ? -1:1;
  rawVal = (int((rxBuffer[21]) << 8) & 0x7F00) | int(rxBuffer[22]);
  temperature = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_TEMP_VALUE;
}

void saveDataPointsToFile()
{
  try {
    fileOutputStream = createWriter(DATAPOINTS_FILENAME);
    int nbLines = heightPlot.getMainLayer().getPoints().getNPoints();
    for (int i=0; i < nbLines; i++)
    {
       fileOutputStream.println( heightPlot.getMainLayer().getPoints().getX(i) + ", "
                                  + heightPlot.getMainLayer().getPoints().getY(i) + ", "
                                  + heightPlot.getLayer("Sensor2").getPoints().getY(i) + ", "
                                  + heightPlot.getLayer("Sensor3").getPoints().getY(i) + ", "
                                  + heightPlot.getLayer("Sensor4").getPoints().getY(i) + ", "
                                  + gyroPoints[0].get(i).getY() + ","
                                  + gyroPoints[1].get(i).getY() + ","
                                  + gyroPoints[2].get(i).getY() + ","
                                  + accelPoints[0].get(i).getY() + ","
                                  + accelPoints[1].get(i).getY() + ","
                                  + accelPoints[2].get(i).getY() );
    }
    fileOutputStream.println();
    fileOutputStream.flush();
    fileOutputStream.close();
  } catch (Exception e) {
    println(e);
  }
}

void setGyroDataImuPlot(boolean value)
{
  if (value)  //Show gyro data on IMU plot
  {
    imuPlot.setTitleText("Vitesse angulaire");
    imuPlot.getYAxis().setAxisLabelText("Vitesse angulaire (°/s)");
    imuPlot.setYLim(-100, 100);
    imuPlot.getMainLayer().setPoints(gyroPoints[0]);
    imuPlot.getLayer("Y").setPoints(gyroPoints[1]);
    imuPlot.getLayer("Z").setPoints(gyroPoints[2]);
  }
  else 
  {
    imuPlot.setTitleText("Accélération linéaire");
    imuPlot.getYAxis().setAxisLabelText("Acceleration lineaire m/s^2)");
    imuPlot.setYLim(-2, 2);
    imuPlot.getMainLayer().setPoints(accelPoints[0]);
    imuPlot.getLayer("Y").setPoints(accelPoints[1]);
    imuPlot.getLayer("Z").setPoints(accelPoints[2]);
  }
}
