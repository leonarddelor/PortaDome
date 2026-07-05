#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <SerialFlash.h>

// GUItool: begin automatically generated code
AudioPlaySdWav           playSdWav1;     //xy=242.1999969482422,169.1999969482422
AudioOutputUSB           usb1;           //xy=497.20003509521484,170.19999885559082
AudioConnection          patchCord1(playSdWav1, 0, usb1, 0);
AudioConnection          patchCord2(playSdWav1, 1, usb1, 1);
// GUItool: end automatically generated code

// Définition de la broche de la carte SD intégrée à la Teensy 3.6
#define SDCARD_CS_PIN    BUILTIN_SDCARD

void setup() {
  Serial.begin(9600);
  
  // Allouer de la mémoire pour le traitement audio
  AudioMemory(16);

  // Initialisation de la carte SD
  if (!(SD.begin(SDCARD_CS_PIN))) {
    while (1) {
      Serial.println("Erreur : Impossible de lire la carte SD !");
      delay(500);
    }
  }
  
  delay(1000);
}

void loop() {
  // Si le lecteur ne joue rien en ce moment...
  if (playSdWav1.isPlaying() == false) {
    Serial.println("Lecture du fichier...");
    
    // Lance le fichier (Assure-toi qu'il s'appelle bien TRACK1.WAV sur ta SD)
    playSdWav1.play("TRACK1.WAV"); 
    
    // Une petite pause pour laisser le temps au flux de démarrer
    delay(500); 
  }
}