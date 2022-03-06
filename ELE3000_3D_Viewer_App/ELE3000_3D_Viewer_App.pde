/**
*  Application de visualisation temps réel d'une plateforme 3D 
*  en lien avec mon projet ELE300 - Genie Electrique
*  Titre du projet: Systeme de positionnement multi-capteurs
*  
*  @author: Alexandre Hebert
*  Cree le: 12/02/2022
*  @version: 1.0
*
*  -------! INFOS !--------
*  Systeme de coordonnees "main gauche" 
*  --> axe x vers la droite de l'ecran
*  --> axe y vers le bas de l'ecran
*  --> axe z qui sort de l'ecran
*  --> camera deplacee pour avoir l'origine au milieu de l'ecran
* ------------//-----------
*/



import processing.serial.*;
import grafica.*;
import peasy.*;

//---------------------------------//
//-----------| CONSTANTS |---------//
//---------------------------------//
final int MAX_RXDATA_LENGTH = 30;
final int MAX_HEIGHT_SENOSR_VALUE = 50;
final int MAX_GYRO_VALUE = 250;
final int MAX_ACCEL_VALUE = 2;
final int MAX_TEMP_VALUE = 100;
final int MAX_ANGLE_VALUE = 90;
final float H_PLOT_X_LIM = 10;
final float IMU_PLOT_X_LIM = 10;
final int SERIAL_RX_THREAD_SLEEP = 10; //En ms
final int WORLD_TO_PIXEL_RATION = 10; //XX pixels pour 1 cm
final float PROTOTYPE_LENGTH = 18.5; //En cm
final float PROTOTYPE_WIDTH = 13.5; //En cm
final PVector CAM_EYE_DEFAULT_POS = new PVector(0, -200, 800);
final PVector DEFAULT_SCENE_CENTER = new PVector(0, -200, 0);


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
float pitchAngle, rollAngle, yawAngle;

boolean serialRxData;
boolean angleOnly;

// Graphics //
PFont appFont;

//PeasyCam cam;

Plateforme plateforme;
PVector modelCenter;
PVector camEyePos;
PVector sceneCenter;
Sol sol;
Fleche fleche;
Graduation grad;

void setup()
{
  size(1200, 900, P3D);
  //Variables initialization
  //cam = new PeasyCam(this, 1000);
  rxBuffer = new byte[40];
  rawHeights = new float[4];
  rawGyro = new float[3];
  rawAccel = new float[3];
  camEyePos = CAM_EYE_DEFAULT_POS.copy();
  sceneCenter = DEFAULT_SCENE_CENTER.copy();
  temperature = 0;
  pitchAngle = 0;
  rollAngle = 0;
  yawAngle = 0;
  modelCenter = new PVector(0, 0, 0);
  serialRxData = true;
  angleOnly = true;
  appFont = loadFont("AgencyFB-Bold-24.vlw");  //This font has been previously created using "Create font..." in processing
    
  
  //Serial connection
  printArray(Serial.list());
  try {
    myPort = new Serial(this, Serial.list()[4], 115200);
  } catch (Exception e) {
    println(e);
  }  
  thread("processRxData");
  //frameRate(60);
  plateforme = new Plateforme(modelCenter, PROTOTYPE_LENGTH, PROTOTYPE_WIDTH, WORLD_TO_PIXEL_RATION, PROTOTYPE_LENGTH, PROTOTYPE_WIDTH);
  plateforme.setPlaneScaling(1.5);
  sol = new Sol(500);
  fleche = new Fleche(new PVector(-100, 0, 0), new PVector(0, -100, 0));
  grad = new Graduation(new PVector(0, 0, 0), new PVector(-sin(PI/4), -cos(PI/4), 0), WORLD_TO_PIXEL_RATION, 20, 5);
}

void draw()
{
  background(0);
  
  // Draw text //
  textFont(appFont);
  textSize(24);
  stroke(255);
  strokeWeight(2);
  fill(255);
  text("Pitch:   " + round(pitchAngle*100)/100.0 + " °", -width/2 + 25, -height/2 + 25);
  text("Roll:   " + round(rollAngle*100)/100.0 + " °", -width/2 + 25, -height/2 + 50);
  text("Yaw:   " + round(yawAngle*100)/100.0 + " °", -width/2 + 25, -height/2 + 75);
  textSize(32);
  if (angleOnly) text("MODE ANGLE",  -50, height/2 - 300);
  else text("MODE HAUTEUR",  -50, height/2 - 300);
  
  camera(camEyePos.x, camEyePos.y, camEyePos.z, // eyeX, eyeY, eyeZ
         sceneCenter.x, sceneCenter.y, sceneCenter.z, // center of the scene
         0.0, 1.0, 0.0);  //Upward direction
  //if (angleOnly) plateforme.setAngles(pitchAngle, rollAngle, 0);
  // else plateforme.estimatePosOnlyHeightPoints(rawHeights[0], rawHeights[1], rawHeights[2], rawHeights[3]);
   plateforme.estimatePosHeightAndIMU(rawHeights, radians(pitchAngle), radians(rollAngle));
  //plateforme.setAngles(0, -90, 0);
  //fleche.display();
  //grad.display();
  plateforme.display();
  sol.display();
  
}

void keyPressed()
{
  switch (key)
  {
    case '1':   // VUE DEVANT //
      camEyePos = CAM_EYE_DEFAULT_POS.copy();
      break;
    case '2':  // 45 degree VUE COTE //
      camEyePos.x = 500;
      camEyePos.y = -400;
      camEyePos.z = 600;
      break;
    case '3': // VUE DESSUS //
      camEyePos.x = 0;
      camEyePos.y = -600;
      camEyePos.z = 10;
      break;
    case 's': 
      angleOnly =! angleOnly;
      break;
  }

}


/**
*  Thread pour reception des donnees via l'interface USART
*/
void processRxData()
{
  while(serialRxData)
  {
    if (myPort != null && myPort.available() >= MAX_RXDATA_LENGTH)
    {
      myPort.readBytes(rxBuffer);
      myPort.clear();
      if (rxBuffer[0] != '$')
      {
        println("Serial reception ERROR");
      }
      else
      {
        // Values conversion //
        int rawVal;
        int sign;
        // Height_1 //
        rawVal = (int(rxBuffer[1]) << 8) | int(rxBuffer[2]);
        rawHeights[0] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
        rawHeights[0] = round(rawHeights[0]*100)/100.0;
        // Height_2 //
        rawVal = (int(rxBuffer[3]) << 8) | int(rxBuffer[4]);
        rawHeights[1] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
        rawHeights[1] = round(rawHeights[1]*100)/100.0;
        // Height_3 //
        rawVal = (int(rxBuffer[5]) << 8) | int(rxBuffer[6]);
        rawHeights[2] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
        rawHeights[2] = round(rawHeights[2]*100)/100.0;
        // Height_4 //
        rawVal = (int(rxBuffer[7]) << 8) | int(rxBuffer[8]);
        rawHeights[3] =  float(rawVal & 0xFFFF) / 65535.0 * MAX_HEIGHT_SENOSR_VALUE;
        rawHeights[3] = round(rawHeights[3]*100)/100.0;
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
        // Pitch Angle //
        sign = (int(rxBuffer[23] >> 7) & 0x01) == 1 ? -1:1;
        rawVal = (int((rxBuffer[23]) << 8) & 0x7F00) | int(rxBuffer[24]);
        pitchAngle = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_ANGLE_VALUE; 
        // Roll Angle //
        sign = (int(rxBuffer[25] >> 7) & 0x01) == 1 ? -1:1;
        rawVal = (int((rxBuffer[25]) << 8) & 0x7F00) | int(rxBuffer[26]);
        rollAngle = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_ANGLE_VALUE; 
        // Yaw Angle //
        sign = (int(rxBuffer[27] >> 7) & 0x01) == 1 ? -1:1;
        rawVal = (int((rxBuffer[27]) << 8) & 0x7F00) | int(rxBuffer[28]);
        yawAngle = sign * float(rawVal & 0x7FFF) / 32767.0 * MAX_ANGLE_VALUE; 
      }
    }
    delay(SERIAL_RX_THREAD_SLEEP);
  }
}
