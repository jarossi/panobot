#include <ThumbJoystick.h>

#include <EEPROM.h>

#include <EEPROMAnything.h>

#include <AccelStepper.h>

#include <LiquidCrystal595.h>

#include <MenuBackend.h>


// Global variables

// Remote Shutter pins
#define focusPin 2
#define shutterPin 3


// LCD constantans and variables
#define lcdBacklightPin 10
#define lcdDataPin 11
#define lcdLatchPin 12
#define lcdClockPin 13

#define lcdColumns 20
#define lcdRows 4

LiquidCrystal595 lcd(lcdDataPin,lcdLatchPin,lcdClockPin);

char lcdBlankLine[]="                    ";


// ThumbJoystick contants and variables
#define joystickSelPin A5
#define joystickXPin A6
#define joystickYPin A7
#define joystickXInvert false
#define joystickYInvert true
#define joystickThreshold 5

ThumbJoystick joystick(joystickSelPin, joystickXPin, joystickYPin, joystickXInvert, joystickYInvert);


// Head constants and variables
#define tiltMotorClockPin 4
#define tiltMotorDirPin 5
#define panMotorClockPin 6
#define panMotorDirPin 7
#define motorsEnablePin 8
#define panCeroSensorPin A0
#define tiltCeroSensorPin A1

AccelStepper tiltMotor(1, tiltMotorClockPin, tiltMotorDirPin);

AccelStepper panMotor(1, panMotorClockPin, panMotorDirPin);


//Config struct

struct config_t {
  // Intervalometer
  unsigned int intervalometerNumberOfPhotos;
  unsigned long intervalometerPreFocusDelay;
  unsigned int intervalometerFocusDelay;
  unsigned long intervalometerShutterDelay;
  unsigned long intervalometerPostShutterDelay;

  // Settings
  byte lcdBacklightValue;
  unsigned int haov;
  unsigned int vaov;
  unsigned int photoOverlapPercent;
  
  unsigned int motorMaxSpeed;
  unsigned int motorAcceleration;
   
  // Move head
  byte motorsEnabledAllTimes;
  
  int minTiltPos;
  int maxTiltPos;
  int tiltHomePos;
  
  int minPanPos;
  int maxPanPos;

  
  // Panorama 
  
  byte verticalPriority;
  
  int panInitPos;
  int tiltInitPos;
  
  int panEndPos;
  int tiltEndPos;
  
};

config_t config;

// Function to edit int
long editInt(long var, long minValue, long maxValue, long increment, int digits){
  long result=var;
  byte joystickreadD;
  int joystickreadA;
  long calincrement=0; 

  lcd.blink();
  
  while(joystickreadD != THUMBJOYSTICK_SEL){
    joystick.updateDigital();
    joystickreadD=joystick.readDigital();
    
    joystickreadA=joystick.getYAxisMaped(-digits,digits);
    
    if (joystickreadA != 0){
        // Calculate increment
        calincrement=increment;        
        for(int i=1; i<abs(joystickreadA); i++){
          calincrement=calincrement*10;
        }
        
        if (joystickreadA < 0) result=constrain(result-calincrement, minValue, maxValue);
         
        if (joystickreadA > 0) result=constrain(result+calincrement, minValue, maxValue);
  
        lcd.setCursor(0,1);  
        lcd.print(lcdBlankLine);
        lcd.setCursor(0,1); 
        lcd.print(result);
        
        delay(250);
      
    }
  }
  lcd.noBlink();
  return result;
}

/*
void editInt2(long *var, long minValue, long maxValue, long increment, int digits){
  long result=*var;
  byte joystickreadD;
  int joystickreadA;
  long calincrement=0; 

  lcd.blink();
  
  while(joystickreadD != THUMBJOYSTICK_SEL){
    joystick.updateDigital();
    joystickreadD=joystick.readDigital();
    
    joystickreadA=joystick.getYAxisMaped(-digits,digits);
    
    if (joystickreadA != 0){
        // Calculate increment
        calincrement=increment;        
        for(int i=1; i<abs(joystickreadA); i++){
          calincrement=calincrement*10;
        }
        
        if (joystickreadA < 0) result=constrain(result-calincrement, minValue, maxValue);
         
        if (joystickreadA > 0) result=constrain(result+calincrement, minValue, maxValue);
  
        lcd.setCursor(0,1);  
        lcd.print(lcdBlankLine);
        lcd.setCursor(0,1); 
        lcd.print(result);
        
        delay(250);
      
    }
  }
  
  lcd.noBlink();
  *var=result;
  //return;
}



double editFloat(double var, double minValue, double maxValue, double increment, int digits){
  double result=var;
  byte joystickreadD;
  int joystickreadA;
  double calincrement=0; 

  lcd.blink();
  
  while(joystickreadD != THUMBJOYSTICK_SEL){
    joystick.updateDigital();
    joystickreadD=joystick.readDigital();
    
    joystickreadA=joystick.getYAxisMaped(-digits,digits);
    
    if (joystickreadA != 0){
        // Calculate increment
        calincrement=increment;        
        for(int i=1; i<abs(joystickreadA); i++){
          calincrement=calincrement*10;
        }
        
        if (joystickreadA < 0) result=constrain(result-calincrement, minValue, maxValue);
         
        if (joystickreadA > 0) result=constrain(result+calincrement, minValue, maxValue);
  
        lcd.setCursor(0,1);  
        lcd.print(lcdBlankLine);
        lcd.setCursor(0,1); 
        lcd.print(result);
        
        delay(250);
      
    }
  }
  lcd.noBlink();
  return result;
}

*/
void intervalometer(unsigned int nphotos, unsigned long pfdelay, unsigned int fdelay, unsigned long sdelay, unsigned long psdelay, boolean verbose){
  int fdelaytemp=fdelay;
  if (verbose == true){
    lcd.blink();
    fdelaytemp=fdelaytemp-49;
  }    
  for (int i=1;i<=nphotos; i++){
    if (verbose == true){
      lcd.setCursor(0, 1);
      lcd.print(lcdBlankLine);
      lcd.setCursor(0, 1);
      lcd.print("Photo: ");
      lcd.print(i);
      lcd.print("/");
      lcd.print(nphotos);
    }
    delay(pfdelay);
    digitalWrite(focusPin, HIGH);
    delay(fdelaytemp);
    digitalWrite(shutterPin, HIGH);
    delay(sdelay);
    digitalWrite(focusPin, LOW);
    digitalWrite(shutterPin, LOW);
    delay(psdelay);
  }
  if (verbose == true){
    lcd.noBlink();
    lcd.setCursor(0, 1);
    lcd.print(lcdBlankLine);
    lcd.setCursor(0, 1);
  }  
}


void moveHead(){
  int joyx;
  int joyy;
  
  lcd.blink(); 
  lcd.setCursor(0,1);
  lcd.print("Pan Pos :");
  lcd .setCursor(0,2);
  lcd.print("Tilt Pos:");
 
  while(joystick.readDigital() != THUMBJOYSTICK_SEL){
    joyx=joystick.getXAxisMaped(-config.motorMaxSpeed,config.motorMaxSpeed);
    joyy=joystick.getYAxisMaped(-config.motorMaxSpeed,config.motorMaxSpeed);
   
    
    if ((joyx<-joystickThreshold) && (panMotor.currentPosition()-1) >= config.minPanPos || ((joyx>joystickThreshold) && (panMotor.currentPosition()+1) <= config.maxPanPos )){
      panMotor.setSpeed(joyx);
      panMotor.runSpeed();
    }
  
    if (((joyy<-joystickThreshold) && (tiltMotor.currentPosition()-1 >= config.minTiltPos) ) || ((joyy>joystickThreshold) && (tiltMotor.currentPosition()+1 <= config.maxTiltPos)) ){
      tiltMotor.setSpeed(joyy);
      tiltMotor.runSpeed();
    }
   
    if((joyx >= -joystickThreshold) && (joyx <= joystickThreshold) && (joyy >= -joystickThreshold) && (joyy <= joystickThreshold) ){
      lcd.setCursor(9,1);
      lcd.print("           ");
      lcd.setCursor(9,1);
      lcd.print((int)panMotor.currentPosition());
      lcd.setCursor(9,2);
      lcd.print("           ");
      lcd.setCursor(9,2);
      lcd.print((int)tiltMotor.currentPosition());
    }
    
    joystick.updateDigital();
  
  }
  
  lcd.noBlink();
  
  panMotor.setSpeed(0);
  tiltMotor.setSpeed(0);
  
  return;
    
}

void panorama(int x1, int y1, int x2, int y2, boolean vertical_prio=false){
  lcd.blink(); 
  lcd.setCursor(0,1);
  lcd.print("Pan Pos :");
  lcd .setCursor(0,2);
  lcd.print("Tilt Pos:");


  int a_inc;
  int b_inc;

  int a = x1;
  int b = y1;

  int ato=x2;
  int bto=y2;
	
  a_inc=config.haov-(int)(((double)config.haov*(double)config.photoOverlapPercent)/(double)100);

  b_inc=config.vaov-(int)(((double)config.vaov*(double)config.photoOverlapPercent)/(double)100);
        
  if (a>ato)
    a_inc=-a_inc;
	
  if (b>bto)
    b_inc=-b_inc;
	
	
  if (vertical_prio){
    for (true; (((a_inc>0) && (a<=ato))||((a_inc<0) && (a>=ato))); a=a+a_inc){
		
      for (true; (((b_inc>0) && (b<=bto))||((b_inc<0) && (b>=bto))); b=b+b_inc){

        panMotor.moveTo(constrain(a, config.minPanPos, config.maxPanPos));
        tiltMotor.moveTo(constrain(b, config.minTiltPos, config.maxTiltPos));
        
        while((panMotor.distanceToGo() != 0) || (tiltMotor.distanceToGo() != 0)){
          panMotor.run();
          tiltMotor.run();
          joystick.updateDigital();
          if (joystick.readDigital() == THUMBJOYSTICK_SEL){
            lcd.setCursor(0,3);
            lcd.print("Cancelling");
            delay(2000);
            lcd.setCursor(0, 1);
            lcd.print(lcdBlankLine);
            lcd.setCursor(0, 2);
            lcd.print(lcdBlankLine);
            lcd.setCursor(0, 3);
            lcd.print(lcdBlankLine);
            lcd.noBlink();
            return;
          }
        }

        lcd.setCursor(9,1);
        lcd.print("           ");
        lcd.setCursor(9,1);
        lcd.print((int)panMotor.currentPosition());
        lcd .setCursor(9,2);
        lcd.print("           ");
        lcd .setCursor(9,2);
        lcd.print((int)tiltMotor.currentPosition());
        
        intervalometer(1, config.intervalometerPreFocusDelay, config.intervalometerFocusDelay, config.intervalometerShutterDelay, config.intervalometerPostShutterDelay, false);
                      
      }
      
      b = b-b_inc;
      b_inc = -b_inc;
		
      if (bto == y2){
	bto=y1;
      }else{
	bto=y2;
      }
    }
  }else{
    for (true; (((b_inc>0) && (b<=bto))||((b_inc<0) && (b>=bto))); b=b+b_inc){
		
      for (true; (((a_inc>0) && (a<=ato))||((a_inc<0) && (a>=ato))); a=a+a_inc){

        panMotor.moveTo(constrain(a, config.minPanPos, config.maxPanPos));
        tiltMotor.moveTo(constrain(b, config.minTiltPos, config.maxTiltPos));

        while((panMotor.distanceToGo() != 0) || (tiltMotor.distanceToGo() != 0)){
          panMotor.run();
          tiltMotor.run();
          joystick.updateDigital();
          if (joystick.readDigital() == THUMBJOYSTICK_SEL){
            lcd.setCursor(0,3);
            lcd.print("Cancelling");
            delay(2000);
            lcd.setCursor(0, 1);
            lcd.print(lcdBlankLine);
            lcd.setCursor(0, 2);
            lcd.print(lcdBlankLine);
            lcd.setCursor(0, 3);
            lcd.print(lcdBlankLine);
            lcd.noBlink();
            return;
          }
          
        }
        
        lcd.setCursor(9,1);
        lcd.print("           ");
        lcd.setCursor(9,1);
        lcd.print((int)panMotor.currentPosition());
        lcd .setCursor(9,2);
        lcd.print("           ");
        lcd .setCursor(9,2);
        lcd.print((int)tiltMotor.currentPosition());
        
        intervalometer(1, config.intervalometerPreFocusDelay, config.intervalometerFocusDelay, config.intervalometerShutterDelay, config.intervalometerPostShutterDelay, false);
        
      }
	a = a-a_inc;
	a_inc = -a_inc;
		
	if (ato == x2){
	  ato=x1;
	}else{
	  ato=x2;
	}
    }
  
  }

  lcd.setCursor(0, 1);
  lcd.print(lcdBlankLine);
  lcd.setCursor(0, 2);
  lcd.print(lcdBlankLine);
  lcd.setCursor(0, 3);
  lcd.print(lcdBlankLine);
  lcd.noBlink();
  return;
}





// this controls the menu backend and the event generation
MenuBackend menu = MenuBackend(menuUseEvent,menuChangeEvent);
	//beneath is list of menu items needed to build the menu
  MenuItem miSettings = MenuItem("Settings");
    MenuItem miHaov = MenuItem("Horizontal AOV");
    MenuItem miVaov = MenuItem("Vertical AOV");
    MenuItem miPhotoOverlapPercent = MenuItem("Photo overlap (%)");
    MenuItem miMotorMaxSpeed = MenuItem("Motor max speed");
    MenuItem miMotorAcceleration = MenuItem("Motor acceleration");
    MenuItem miMinTiltPos = MenuItem("Min tilt position");
    MenuItem miMaxTiltPos = MenuItem("Max tilt position");
    MenuItem miTiltHomePos = MenuItem("Tilt home position");
    MenuItem miMinPanPos = MenuItem("Min pan position");
    MenuItem miMaxPanPos = MenuItem("Max pan position");
    MenuItem miBacklight = MenuItem("Backlight");
    MenuItem miSave = MenuItem("Save all settings");		
        
  MenuItem miIntervalometer = MenuItem("Intervalometer");
    MenuItem miIntervalometerNumberOfPhotos("Number of photos");
    MenuItem miIntervalometerPreFocusDelay("Pre focus delay");
    MenuItem miIntervalometerFocusDelay("Focus delay");
    MenuItem miIntervalometerShutterDelay("Shutter delay");
    MenuItem miIntervalometerPostShutterDelay("Post shutter delay");
    MenuItem miIntervalometerRun("Run intervalomenter"); 
      
  MenuItem miMoveHead = MenuItem("Move head");
    MenuItem miMotorsEnabledAllTimes = MenuItem("Mtrs enbld all times");
    MenuItem miMoveHeadRun = MenuItem("Run move head");

  MenuItem miPanorama = MenuItem("Panorama");
    MenuItem miVerticalPriority = MenuItem("Vertical priority");
    MenuItem miInitPos = MenuItem("Initial position");
    MenuItem miEndPos = MenuItem("End position");
    MenuItem miPanoramaRun = MenuItem("Run panorama");

	
//this function builds the menu and connects the correct items together
void menuSetup(){
  //add the file menu to the menu root
  menu.getRoot().add(miSettings); 
  //setup the settings menu item
    miSettings.addRight(miHaov);
      miVaov.addBefore(miHaov);
      miVaov.addLeft(miSettings);
     
      miPhotoOverlapPercent.addBefore(miVaov);
      miPhotoOverlapPercent.addLeft(miSettings);
    
      miMotorMaxSpeed.addBefore(miPhotoOverlapPercent);
      miMotorMaxSpeed.addLeft(miSettings);
      
      miMotorAcceleration.addBefore(miMotorMaxSpeed);
      miMotorAcceleration.addLeft(miSettings);
      
      miMinTiltPos.addBefore(miMotorAcceleration);
      miMinTiltPos.addLeft(miSettings);
      
      miMaxTiltPos.addBefore(miMinTiltPos);
      miMaxTiltPos.addLeft(miSettings);

      miTiltHomePos.addBefore(miMaxTiltPos);
      miTiltHomePos.addLeft(miSettings);
      
      miMinPanPos.addBefore(miTiltHomePos);
      miMinPanPos.addLeft(miSettings);

      miMaxPanPos.addBefore(miMinPanPos);
      miMaxPanPos.addLeft(miSettings);
                           
      miBacklight.addBefore(miMaxPanPos);
      miBacklight.addLeft(miSettings);
           
      miSave.addBefore(miBacklight);
      miSave.addLeft(miSettings);
                        
      miHaov.addLeft(miSettings);

    miSettings.addAfter(miSettings);
    
    miIntervalometer.addBefore(miSettings);
      miIntervalometer.addRight(miIntervalometerNumberOfPhotos);
        miIntervalometerPreFocusDelay.addBefore(miIntervalometerNumberOfPhotos);
        miIntervalometerPreFocusDelay.addLeft(miIntervalometer);
        
        miIntervalometerFocusDelay.addBefore(miIntervalometerPreFocusDelay);
        miIntervalometerFocusDelay.addLeft(miIntervalometer);
        
        miIntervalometerShutterDelay.addBefore(miIntervalometerFocusDelay);
        miIntervalometerShutterDelay.addLeft(miIntervalometer);
        
        miIntervalometerPostShutterDelay.addBefore(miIntervalometerShutterDelay);
        miIntervalometerPostShutterDelay.addLeft(miIntervalometer);
        
        miIntervalometerRun.addBefore(miIntervalometerPostShutterDelay);
        miIntervalometerRun.addLeft(miIntervalometer);
        
        miIntervalometerNumberOfPhotos.addLeft(miIntervalometer);    
    
   
    
    miMoveHead.addBefore(miIntervalometer);
      miMoveHead.addRight(miMotorsEnabledAllTimes);
        miMoveHeadRun.addBefore(miMotorsEnabledAllTimes);
        miMoveHeadRun.addLeft(miMoveHead);
      
      miMotorsEnabledAllTimes.addLeft(miMoveHead);
        
    miPanorama.addBefore(miMoveHead);
      miPanorama.addRight(miVerticalPriority);
        miInitPos.addBefore(miVerticalPriority);
        miInitPos.addLeft(miPanorama);
        
        miEndPos.addBefore(miInitPos);
        miEndPos.addLeft(miPanorama);
              
        miPanoramaRun.addBefore(miEndPos);
        miPanoramaRun.addLeft(miPanorama);
        
      miVerticalPriority.addLeft(miPanorama);
}

/*
	This is an important function
	Here all use events are handled
	
	This is where you define a behaviour for a menu item
*/
void menuUseEvent(MenuUseEvent used){	

  // comparison agains a known item
  // Settings
  if(used.item == miHaov)
    config.haov=editInt(config.haov, 0, 2500, 1, 3);
  
  if(used.item == miVaov)
    config.vaov=editInt(config.vaov, 0, 2500, 1, 3);
  
  if(used.item == miMotorMaxSpeed){
    config.motorMaxSpeed=editInt(config.motorMaxSpeed, 1, 2000, 1, 3);
    panMotor.setMaxSpeed(config.motorMaxSpeed);
    tiltMotor.setMaxSpeed(config.motorMaxSpeed);
  }
    
  if(used.item == miMotorAcceleration){
    config.motorAcceleration=editInt(config.motorAcceleration, 1, 2000, 1, 3);
    panMotor.setAcceleration(config.motorAcceleration);
    tiltMotor.setAcceleration(config.motorAcceleration);
  }
   
  if(used.item == miMinTiltPos)
    config.minTiltPos=editInt(config.minTiltPos, -2500, 2500, 1, 3);
  
  if(used.item == miMaxTiltPos)
    config.maxTiltPos=editInt(config.maxTiltPos, -2500, 2500, 1, 3);
  
  if(used.item == miTiltHomePos){
    config.tiltHomePos=editInt(config.tiltHomePos, config.minTiltPos, config.maxTiltPos, 1, 3);
    tiltMotor.setCurrentPosition(config.tiltHomePos); 
  }

    
  if(used.item == miMinPanPos)
    config.minPanPos=editInt(config.minPanPos, -2500, 2500, 1, 3);
    
  if(used.item == miMaxPanPos)
    config.maxPanPos=editInt(config.maxPanPos, -2500, 2500, 1, 3);
  
  if(used.item == miPhotoOverlapPercent)
    config.photoOverlapPercent=editInt(config.photoOverlapPercent, 1, 99, 1, 2);
  
  
  if(used.item == miBacklight){
    config.lcdBacklightValue=editInt(config.lcdBacklightValue, 0, 255, 1, 2);
    analogWrite(lcdBacklightPin, config.lcdBacklightValue);  
  }
  
  if(used.item == miSave){
    lcd.setCursor(0,1);
    EEPROM_writeAnything(0, config);
    lcd.print("Saved");
    delay(1000);
    lcd.setCursor(0,1);
    lcd.print(lcdBlankLine);
  }
  

  // Intervalometer
  if (used.item == miIntervalometerNumberOfPhotos)
    config.intervalometerNumberOfPhotos = editInt(config.intervalometerNumberOfPhotos, 1, 2000, 1, 3);
  
  
  if (used.item == miIntervalometerPreFocusDelay)
    config.intervalometerPreFocusDelay = editInt(config.intervalometerPreFocusDelay, 0, 10000000, 10, 5);    
  

  if (used.item == miIntervalometerFocusDelay)
    config.intervalometerFocusDelay = editInt(config.intervalometerFocusDelay, 49, 30000, 1, 4);
  

  if (used.item == miIntervalometerShutterDelay)
    config.intervalometerShutterDelay = editInt(config.intervalometerShutterDelay, 0, 3600000, 10, 5);
  

  if (used.item == miIntervalometerPostShutterDelay)
    config.intervalometerPostShutterDelay = editInt(config.intervalometerPostShutterDelay, 0, 10000000, 10, 5);
  

  if (used.item == miIntervalometerRun)
    intervalometer(config.intervalometerNumberOfPhotos, config.intervalometerPreFocusDelay, config.intervalometerFocusDelay, config.intervalometerShutterDelay, config.intervalometerPostShutterDelay, true);
    
  // Move Head
  
  if(used.item == miMotorsEnabledAllTimes){
    config.motorsEnabledAllTimes = editInt(config.motorsEnabledAllTimes, 0, 1, 1, 1);
    if (config.motorsEnabledAllTimes == 0){
      tiltMotor.runToNewPosition(config.tiltHomePos);
      //Disable Motors
      digitalWrite(motorsEnablePin, LOW);
    } else {
      digitalWrite(motorsEnablePin, HIGH);
    }
  }
  
  if(used.item == miMoveHeadRun){
    //Enable Motors Anyways
    digitalWrite(motorsEnablePin, HIGH);
    
    moveHead();
    
    if (config.motorsEnabledAllTimes == 0){
      tiltMotor.runToNewPosition(config.tiltHomePos);
      //Disable Motors
      digitalWrite(motorsEnablePin, LOW);
    }
    lcd.setCursor(0,1);
    lcd.print(lcdBlankLine);
    lcd.setCursor(0,2);
    lcd.print(lcdBlankLine);
  }


  // Panorama
  if (used.item == miVerticalPriority)
    config.verticalPriority = editInt(config.verticalPriority, 0, 1, 1, 1);


  if (used.item == miInitPos){
    //Enable Motors Anyways
    digitalWrite(motorsEnablePin, HIGH);
    
    moveHead();
    
    config.panInitPos = panMotor.currentPosition();
    config.tiltInitPos = tiltMotor.currentPosition();
    
    if (config.motorsEnabledAllTimes == 0){
      tiltMotor.runToNewPosition(config.tiltHomePos);
      //Disable Motors
      digitalWrite(motorsEnablePin, LOW);
    }
    
  }

  if (used.item == miEndPos){
     //Enable Motors Anyways
    digitalWrite(motorsEnablePin, HIGH);
    
    moveHead();
    
    config.panEndPos = panMotor.currentPosition();
    config.tiltEndPos = tiltMotor.currentPosition();
    
    if (config.motorsEnabledAllTimes == 0){
      tiltMotor.runToNewPosition(config.tiltHomePos);
      //Disable Motors
      digitalWrite(motorsEnablePin, LOW);
    }
    
  }
  
  if (used.item == miPanoramaRun){
    //Enable Motors Anyways
    digitalWrite(motorsEnablePin, HIGH);
    panorama(config.panInitPos,config.tiltInitPos,config.panEndPos,config.tiltEndPos,config.verticalPriority);
    if (config.motorsEnabledAllTimes == 0){
      tiltMotor.runToNewPosition(config.tiltHomePos);
      //Disable Motors
      digitalWrite(motorsEnablePin, LOW);
    }
    
  }

  
}

/*
	This is an important function
	Here we get a notification whenever the user changes the menu
	That is, when the menu is navigated
*/
void menuChangeEvent(MenuChangeEvent changed){
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(changed.to.getName());
  lcd.setCursor(0, 1);
        
  // Print current value for settings
  if (changed.to == miHaov)
    lcd.print(config.haov);
  
  if (changed.to == miVaov)
    lcd.print(config.vaov);
  
  if (changed.to == miPhotoOverlapPercent)
    lcd.print(config.photoOverlapPercent);
  
  if (changed.to == miMotorMaxSpeed)
    lcd.print(config.motorMaxSpeed);
  
  if (changed.to == miMotorAcceleration)
    lcd.print(config.motorAcceleration);
  
  if (changed.to == miMinTiltPos)
    lcd.print(config.minTiltPos);
  
  if (changed.to == miMaxTiltPos)
    lcd.print(config.maxTiltPos);
    
  if (changed.to == miTiltHomePos)
    lcd.print(config.tiltHomePos);
    
  if (changed.to == miMinPanPos)
    lcd.print(config.minPanPos);
  
  if (changed.to == miMaxPanPos)
    lcd.print(config.maxPanPos);
  
  if (changed.to == miBacklight)
    lcd.print((int)config.lcdBacklightValue);
  
  
  // Print current values for intevalometer
     
  if (changed.to == miIntervalometerNumberOfPhotos)
    lcd.print(config.intervalometerNumberOfPhotos);
  
  if (changed.to ==  miIntervalometerPreFocusDelay)
    lcd.print(config.intervalometerPreFocusDelay);
  
  if (changed.to == miIntervalometerFocusDelay)
    lcd.print(config.intervalometerFocusDelay);
  
  if (changed.to == miIntervalometerShutterDelay)
    lcd.print(config.intervalometerShutterDelay);
  
  if (changed.to == miIntervalometerPostShutterDelay)
    lcd.print(config.intervalometerPostShutterDelay);
  
  
  // Print current value for move head
  if (changed.to == miMotorsEnabledAllTimes)
    lcd.print((int)config.motorsEnabledAllTimes);
    
    
  // Print current values for panorama
  if (changed.to == miVerticalPriority)
    lcd.print((int)config.verticalPriority);
  
  if (changed.to == miInitPos){
    lcd.setCursor(0,1);
    lcd.print("Pan Pos :");
    lcd.print(config.panInitPos);
    lcd .setCursor(0,2);
    lcd.print("Tilt Pos:");
    lcd.print(config.tiltInitPos);
  }
  
  if (changed.to == miEndPos){
    lcd.setCursor(0,1);
    lcd.print("Pan Pos :");
    lcd.print(config.panEndPos);
    lcd .setCursor(0,2);
    lcd.print("Tilt Pos:");
    lcd.print(config.tiltEndPos);
  }
       
}


void setup() {  

  // Init config with something
  config.intervalometerNumberOfPhotos=10;
  config.intervalometerPreFocusDelay=0;
  config.intervalometerFocusDelay=2000;
  config.intervalometerShutterDelay=10;
  config.intervalometerPostShutterDelay=1000;
  config.lcdBacklightValue=128;


  // Read config
  EEPROM_readAnything(0, config);
  
  // Set the backlight on
  pinMode(lcdBacklightPin, OUTPUT);
  analogWrite(lcdBacklightPin, config.lcdBacklightValue);
  
  
  // Init focus and shutter pins
  pinMode(focusPin, OUTPUT);
  pinMode(shutterPin, OUTPUT);
  digitalWrite(focusPin, LOW);
  digitalWrite(shutterPin, LOW);
 
  // Init the LCD
  lcd.begin(lcdColumns, lcdRows);
  
  // Init the joystick
  joystick.setZeros();
  
  // Init the menu
  menuSetup();
  menu.moveDown();
  
  // Init the head
  pinMode(panMotorClockPin, OUTPUT);
  pinMode(panMotorDirPin, OUTPUT);
  pinMode(tiltMotorClockPin, OUTPUT);
  pinMode(tiltMotorDirPin, OUTPUT);
  pinMode(motorsEnablePin, OUTPUT);
  
 
  pinMode(panCeroSensorPin, INPUT);
  pinMode(tiltCeroSensorPin, INPUT);
  
  digitalWrite(motorsEnablePin, LOW);
  digitalWrite(panMotorDirPin, LOW);
  digitalWrite(tiltMotorDirPin, LOW);
  
  
  panMotor.setMaxSpeed(config.motorMaxSpeed);
  panMotor.setAcceleration(config.motorAcceleration);
  tiltMotor.setMaxSpeed(config.motorMaxSpeed);
  tiltMotor.setAcceleration(config.motorAcceleration);
  tiltMotor.setCurrentPosition(config.tiltHomePos);
  
  // Init the serial port  
  //Serial.begin(9600);
   
}

void loop() {
        joystick.updateDigital();
        byte joystickread = joystick.readDigital();
	if (joystickread != THUMBJOYSTICK_NULL){
                switch (joystickread) {
			case THUMBJOYSTICK_UP: menu.moveUp(); break;
			case THUMBJOYSTICK_DOWN: menu.moveDown(); break;
			case THUMBJOYSTICK_RIGHT: menu.moveRight(); break;
			case THUMBJOYSTICK_LEFT: menu.moveLeft(); break;
			case THUMBJOYSTICK_SEL: menu.use(); break;
		}
        }	
}

