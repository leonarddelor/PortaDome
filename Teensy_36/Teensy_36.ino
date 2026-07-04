#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <SerialFlash.h>

// Création des objets Audio
AudioPlaySdWav           playWav1;       
AudioOutputUSB           audioOutput;    // Envoie l'audio vers le PC via l'USB

// Connexion du lecteur SD vers la sortie USB (Canal Gauche et Droite)
AudioConnection          patchCord1(playWav1, 0, audioOutput, 0);
AudioConnection          patchCord2(playWav1, 1, audioOutput, 1);

// Utiliser le lecteur de carte SD intégré de la Teensy 3.6
#define SDCARD_CS_PIN    BUILTIN_SDCARD

void setup() {
  Serial.begin(9600);
  
  // Allouer de la mémoire pour le traitement audio
  AudioMemory(16);

  // Initialisation de la carte SD intégrée
  if (!(SD.begin(SDCARD_CS_PIN))) {
    while (1) {
      Serial.println("Erreur : Impossible de lire la carte SD !");
      delay(500);
    }
  }
  
  delay(1000);
}

void loop() {
  if (playWav1.isPlaying() == false) {
    Serial.println("Lecture du fichier...");
    // Remplace "TRACK1.WAV" par le nom exact de ton fichier sur la SD
    playWav1.play("TRACK1.WAV"); 
    delay(10); // Court délai pour laisser le lecteur s'initialiser
  }
}