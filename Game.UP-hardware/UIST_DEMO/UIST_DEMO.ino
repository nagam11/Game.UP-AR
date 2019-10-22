#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TaskScheduler.h>
#include <Arduino.h>
#include <CapacitiveSensor.h>
#include <NeoPixelBus.h>

/** ============= BLUETOOTH SERVICES AND CHARACTERISTICS =============**/
#define SERVICE_UUID               "9a8ca9ef-e43f-4157-9fee-c37a3d7dc12d"
// LED char
#define B1_UUID                    "e94f85c8-7f57-4dbd-b8d3-2b56e107ed60"
#define B2_UUID                    "a8985fda-51aa-4f19-a777-71cf52abba1e"
#define B4_UUID                    "4fde9fc5-a828-40c6-a728-3fe2a5bc88b9"
#define B6_UUID                    "ec666639-a88e-4166-a7ba-dd59a2fabfc1"
#define B7_UUID                    "ebd771ed-068d-46ea-bf28-80c8f2db9191"
#define B8_UUID                    "34990849-3601-45cf-b7cd-cb7f2d36335f"
//Single touch UUID: 0:B1 1:B2 2:B3 3:B4 4:B5 5:B6
#define TOUCH_UUID                 "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define B1_LONG_TOUCH_UUID          "15e50854-bd25-433b-a658-5daa580c77c7"
#define B2_LONG_TOUCH_UUID          "670f01ff-3d98-453b-aa41-c12e9deacf8d"
#define B4_LONG_TOUCH_UUID          "f58793d0-61e0-4d1b-87be-b8eb79ac9948"
#define B6_LONG_TOUCH_UUID          "5b9efa1d-725c-48a3-a910-6ca4fe325981"
#define B3_LONG_TOUCH_UUID          "ab31a51e-7cbc-4de3-8e67-d48bd8ad6f7a"
#define B5_LONG_TOUCH_UUID          "403828e6-6b6e-4273-9c92-3c4c13cffe0c"
#define B7_LONG_TOUCH_UUID          "455bf338-29c2-4a9f-a6ff-5fa0dfd04af9"
#define B8_LONG_TOUCH_UUID          "d32158df-7837-4a56-9c71-816f1122e3c3"

#define DEVINFO_UUID              (uint16_t)0x180a
#define DEVINFO_MANUFACTURER_UUID (uint16_t)0x2a29
#define DEVINFO_NAME_UUID         (uint16_t)0x2a24
#define DEVINFO_SERIAL_UUID       (uint16_t)0x2a25
#define DEVICE_MANUFACTURER  "WROOM"
#define DEVICE_NAME    "Marla_ESP32"

// BLE server
BLEServer* pServer = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool firstCon = true;
Scheduler scheduler;

BLECharacteristic *pCharB1;
BLECharacteristic *pCharB2;
BLECharacteristic *pCharB4;
BLECharacteristic *pCharB6;
BLECharacteristic *pCharB7;
BLECharacteristic *pCharB8;
BLECharacteristic *pTouch;
BLECharacteristic *pCharB1_LONG_TOUCH;
BLECharacteristic *pCharB2_LONG_TOUCH;
BLECharacteristic *pCharB3_LONG_TOUCH;
BLECharacteristic *pCharB4_LONG_TOUCH;
BLECharacteristic *pCharB5_LONG_TOUCH;
BLECharacteristic *pCharB6_LONG_TOUCH;
BLECharacteristic *pCharB7_LONG_TOUCH;
BLECharacteristic *pCharB8_LONG_TOUCH;

/** ======================= LEDs =====================================**/
#define B1_LED 23
#define B2_LED 22
#define B4_LED 21
#define B6_LED 19
#define B7_LED 5
#define B8_LED 16
#define colorSaturation 255
// Number of LEDs in NeopixelB2_strip
#define COUNT 3
#define B4_COUNT 6
// 220 Ohm resistor for Neopixels. 5V power from ESP32.
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B1_strip(COUNT, B1_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B2_strip(COUNT, B2_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B4_strip(B4_COUNT, B4_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B6_strip(COUNT, B6_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B7_strip(COUNT, B7_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B8_strip(COUNT, B8_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> LEDs_STRIP[] = {B1_strip, B2_strip, B4_strip, B6_strip};
RgbColor red(colorSaturation, 0, 0);
RgbColor green(0, colorSaturation, 0);
RgbColor blue(0, 0, colorSaturation);
RgbColor black(0);
// Keep track of LED states
bool B1_LED_ON = false;
bool B2_LED_ON = false;
bool B3_LED_ON = false;
bool B4_LED_ON = false;
bool B5_LED_ON = false;
bool B6_LED_ON = false;
// Keep track of type of highlight for B4. False for RESIDENTIAL, true for AGE
bool B4_highlight_type = false;

/** ======================= Touch ====================================**/

CapacitiveSensor   B1_Touch = CapacitiveSensor(4, 2);        // 10M resistor between 4 & 2, 2 is sensor LED PIN.
CapacitiveSensor   B2_Touch = CapacitiveSensor(4, 15);       // 10M resistor between 4 & 15, 15 is sensor LED PIN.
CapacitiveSensor   B3_Touch = CapacitiveSensor(4, 33);       // 10M resistor between 4 & 33, 33 is sensor LED PIN.
CapacitiveSensor   B4_Touch = CapacitiveSensor(4, 32);       // 10M resistor between 4 & 32, 32 is sensor LED PIN.
CapacitiveSensor   B5_Touch = CapacitiveSensor(4, 27);       // 10M resistor between 4 & 27, 27 is sensor LED PIN.
CapacitiveSensor   B6_Touch = CapacitiveSensor(4, 14);       // 10M resistor between 4 & 14, 14 is sensor LED PIN.
CapacitiveSensor   B7_Touch = CapacitiveSensor(4, 12);       // 10M resistor between 4 & 12, 12 is sensor LED PIN.
CapacitiveSensor   B8_Touch = CapacitiveSensor(4, 13);       // 10M resistor between 4 & 13, 13 is sensor LED PIN.

const unsigned long long_touch = 2000;
// Current touch: 0 B1, 1 for B2, 2  for B3 , 3 for B4, 4 for B5 , 5 for B6 6 for nothing
uint8_t touch = 8;
// 0 for no long touches, 1 for one unit of long touch where 1 unit is 700 ms. 2 for 2 units and so on.
uint8_t B1_LONG_TOUCH = 0;
uint8_t B2_LONG_TOUCH = 0;
uint8_t B3_LONG_TOUCH = 0;
uint8_t B4_LONG_TOUCH = 0;
uint8_t B5_LONG_TOUCH = 0;
uint8_t B6_LONG_TOUCH = 0;
uint8_t B7_LONG_TOUCH = 0;
uint8_t B8_LONG_TOUCH = 0;
bool B1_Touch_started = false;
bool B2_Touch_started = false;
bool B3_Touch_started = false;
bool B4_Touch_started = false;
bool B5_Touch_started = false;
bool B6_Touch_started = false;
bool B7_Touch_started = false;
bool B8_Touch_started = false;
unsigned long B1_Touch_begin;
unsigned long B2_Touch_begin;
unsigned long B3_Touch_begin;
unsigned long B4_Touch_begin;
unsigned long B5_Touch_begin;
unsigned long B6_Touch_begin;
unsigned long B7_Touch_begin;
unsigned long B8_Touch_begin;
unsigned long B1_LAST_TOUCH;
unsigned long B2_LAST_TOUCH;
unsigned long B3_LAST_TOUCH;
unsigned long B4_LAST_TOUCH;
unsigned long B5_LAST_TOUCH;
unsigned long B6_LAST_TOUCH;
unsigned long B7_LAST_TOUCH;
unsigned long B8_LAST_TOUCH;
long B1_current_long_delay;
long B1_recent_long_delay;
long B2_current_long_delay;
long B2_recent_long_delay;
long B3_current_long_delay;
long B3_recent_long_delay;
long B4_current_long_delay;
long B4_recent_long_delay;
long B5_current_long_delay;
long B5_recent_long_delay;
long B6_current_long_delay;
long B6_recent_long_delay;
long B7_current_long_delay;
long B7_recent_long_delay;
long B8_current_long_delay;
long B8_recent_long_delay;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println("Connected");
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println("Disconnected");
      deviceConnected = false;
    }
};

class B1_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B1 Command");
      // 0: turn off, 1: green , 2: red 3: blue
      uint8_t v = value[0];
      Serial.println(value.c_str());
      if (v == 0){   
          Serial.print("B1");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B1");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B1");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B1");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

void colorPixels(RgbColor c) {
  for (uint32_t j = 0; j < COUNT; j++) {
        B1_strip.SetPixelColor(j, c);
      }
      delay(1);
      B1_strip.Show();
}
};

class B2_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B2 Command");
      // 0: turn off, 1: green , 2: red 3: blue
      uint8_t v = value[0];
      Serial.println(value.c_str());
      if (v == 0){   
          Serial.print("B2");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B2");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B2");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B2");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

void colorPixels(RgbColor c) {
  for (uint32_t j = 0; j < COUNT; j++) {
        B2_strip.SetPixelColor(j, c);
      }
      delay(1);
      B2_strip.Show();
}
};

class B4_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B4 Command");
      // 0: turn off, 1: green , 2: red 3: blue
      uint8_t v = value[0];
      Serial.println(value.c_str());
      if (v == 0){   
          Serial.print("B4");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B4");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B4");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B4");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

void colorPixels(RgbColor c) {
  for (uint32_t j = 0; j < B4_COUNT; j++) {
        B4_strip.SetPixelColor(j, c);
      }
      delay(1);
      B4_strip.Show();
}
};

class B6_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B6 Command");
      // 0: turn off, 1: green , 2: red 3: blue
      uint8_t v = value[0];
      Serial.println(value.c_str());
      if (v == 0){   
          Serial.print("B6");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B6");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B6");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B6");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

void colorPixels(RgbColor c) {
  for (uint32_t j = 0; j < COUNT; j++) {
        B6_strip.SetPixelColor(j, c);
      }
      delay(1);
      B6_strip.Show();
}
};

class B7_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B7 Command");
      // 0: turn off, 1: green , 2: red 3: blue
      uint8_t v = value[0];
      Serial.println(value.c_str());
      if (v == 0){   
          Serial.print("B7");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B7");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B7");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B7");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

void colorPixels(RgbColor c) {
  for (uint32_t j = 0; j < COUNT; j++) {
        B7_strip.SetPixelColor(j, c);
      }
      delay(1);
      B7_strip.Show();
}
};
class B8_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B8 Command");
      // 0: turn off, 1: green , 2: red 3: blue
      uint8_t v = value[0];
      Serial.println(value.c_str());
      if (v == 0){   
          Serial.print("B8");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B8");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B8");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B8");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

void colorPixels(RgbColor c) {
  for (uint32_t j = 0; j < COUNT; j++) {
        B8_strip.SetPixelColor(j, c);
      }
      delay(1);
      B8_strip.Show();
}
};


/*class B7_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B7 Command");
      // 0: turn off LEDs, 1: green (role), 2: red (age) 3: blue (building selected)
      uint8_t v = value[0];
      Serial.println(v);
      if (v == 0){   
          Serial.print("B7");
          Serial.println(" OFF");
          colorPixels(black);                
        } else if (v == 1){          
          Serial.print("B7");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B7");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B7");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

  void colorPixels(RgbColor c) {
    for (uint32_t j = 0; j < COUNT; j++) {
          B7_strip.SetPixelColor(j, c);
        }
        delay(1);
        B7_strip.Show();
  }
};

class B8_Callbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      Serial.println("B8 Command");
      // 0: turn off LEDs, 1: green (role), 2: red (age) 3: blue (building selected)
      uint8_t v = value[0];
      Serial.println(v);
     if (v == 0){   
          Serial.print("B8");
          Serial.println(" OFF");
          colorPixels(black);                    
        } else if (v == 1){          
          Serial.print("B8");
          Serial.println(" ON- green");         
          colorPixels(green);          
        }else if (v == 2){          
          Serial.print("B8");
          Serial.println("ON - red");         
          colorPixels(red);          
        } else if (v == 3){          
          Serial.print("B8");
          Serial.println("ON - blue");         
          colorPixels(blue);          
        }else {
        Serial.println("Invalid data received");
      }
    }

  void colorPixels(RgbColor c) {
    for (uint32_t j = 0; j < COUNT; j++) {
          B8_strip.SetPixelColor(j, c);
        }
        delay(1);
        B8_strip.Show();
  }
};*/

void setup() {
  Serial.begin(115200);
  Serial.println("Starting...");
  pinMode(B1_LED, OUTPUT);
  pinMode(B2_LED, OUTPUT);
  pinMode(B4_LED, OUTPUT);
  pinMode(B6_LED, OUTPUT);
  pinMode(B7_LED, OUTPUT);
  pinMode(B8_LED, OUTPUT);
  B4_Touch.set_CS_AutocaL_Millis(0xFFFFFFFF);
  B1_strip.Begin();
  B2_strip.Begin();
  B4_strip.Begin();
  B6_strip.Begin();
  B7_strip.Begin();
  B8_strip.Begin();
  B1_strip.Show();
  B2_strip.Show();
  B4_strip.Show();
  B6_strip.Show();
  B7_strip.Show();
  B8_strip.Show();

  String devName = "Marla_ESP32";
  String chipId = String((uint32_t)(ESP.getEfuseMac() >> 24), HEX);
  devName += '_';
  devName += chipId;

  // Create the BLE Device
  BLEDevice::init(devName.c_str());

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  //BLEService *pService = pServer->createService(SERVICE_UUID);
  BLEService *pService = pServer->createService(BLEUUID(SERVICE_UUID), 25);

  pCharB1 = pService->createCharacteristic(B1_UUID, BLECharacteristic::PROPERTY_READ  | BLECharacteristic::PROPERTY_WRITE);
  pCharB1->setCallbacks(new B1_Callbacks());
  //pCharB1->addDescriptor(new BLE2902());

  pCharB2 = pService->createCharacteristic(B2_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pCharB2->setCallbacks(new B2_Callbacks());
  //pCharB2->addDescriptor(new BLE2902());

  pCharB7 = pService->createCharacteristic(B7_UUID, BLECharacteristic::PROPERTY_READ  | BLECharacteristic::PROPERTY_WRITE);
  pCharB7->setCallbacks(new B7_Callbacks());

  pCharB8 = pService->createCharacteristic(B8_UUID, BLECharacteristic::PROPERTY_READ  | BLECharacteristic::PROPERTY_WRITE);
  pCharB8->setCallbacks(new B8_Callbacks());

  pCharB4 = pService->createCharacteristic(B4_UUID, BLECharacteristic::PROPERTY_READ  | BLECharacteristic::PROPERTY_WRITE);
  pCharB4->setCallbacks(new B4_Callbacks());
  //pCharB4->addDescriptor(new BLE2902());

  pCharB6 = pService->createCharacteristic(B6_UUID, BLECharacteristic::PROPERTY_READ  | BLECharacteristic::PROPERTY_WRITE);
  pCharB6->setCallbacks(new B6_Callbacks());
  //pCharB6->addDescriptor(new BLE2902());

  pTouch = pService->createCharacteristic(TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  //pTouch->addDescriptor(new BLE2902());

  pCharB3_LONG_TOUCH = pService->createCharacteristic(B3_LONG_TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  pCharB5_LONG_TOUCH = pService->createCharacteristic(B5_LONG_TOUCH_UUID , BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE);
  pCharB7_LONG_TOUCH = pService->createCharacteristic(B7_LONG_TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  pCharB1_LONG_TOUCH = pService->createCharacteristic(B1_LONG_TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  pCharB2_LONG_TOUCH = pService->createCharacteristic(B2_LONG_TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  //pCharB5_LONG_TOUCH->addDescriptor(new BLE2902());
  pCharB4_LONG_TOUCH = pService->createCharacteristic(B4_LONG_TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  //pCharB4_LONG_TOUCH->addDescriptor(new BLE2902());
  pCharB6_LONG_TOUCH = pService->createCharacteristic(B6_LONG_TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  
  // Start the service
  pService->start();

  pService = pServer->createService(DEVINFO_UUID);
  BLECharacteristic *pChar = pService->createCharacteristic(DEVINFO_MANUFACTURER_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_MANUFACTURER);
  pChar = pService->createCharacteristic(DEVINFO_NAME_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_NAME);
  pChar = pService->createCharacteristic(DEVINFO_SERIAL_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(chipId.c_str());

  pService->start();

  // ----- Advertising

  BLEAdvertising *pAdvertising = pServer->getAdvertising();

  BLEAdvertisementData adv;
  adv.setName(devName.c_str());
  pAdvertising->setAdvertisementData(adv);

  BLEAdvertisementData adv2;
  adv2.setCompleteServices(BLEUUID(SERVICE_UUID));
  pAdvertising->setScanResponseData(adv2);

  pAdvertising->start();

  Serial.println("Ready");
  Serial.print("Device name: ");
  Serial.println(devName);
}

void loop() {
  scheduler.execute();

  // Notify on Touch
  if (deviceConnected) {
    if (firstCon){
    turnOff();
    firstCon = false;
  }
    long start = millis();
    long current_B1_delay = start - B1_Touch_begin;
    long current_B2_delay = start - B2_Touch_begin;
    long current_B3_delay = start - B3_Touch_begin;
    long current_B5_delay = start - B5_Touch_begin;
    long current_B4_delay = start - B4_Touch_begin;
    long current_B6_delay = start - B6_Touch_begin;
    long current_B7_delay = start - B7_Touch_begin;
    long current_B8_delay = start - B8_Touch_begin;
    B1_current_long_delay = start - B1_recent_long_delay;
    B2_current_long_delay = start - B2_recent_long_delay;
    B3_current_long_delay = start - B3_recent_long_delay;
    B5_current_long_delay = start - B5_recent_long_delay;
    B4_current_long_delay = start - B4_recent_long_delay;
    B6_current_long_delay = start - B6_recent_long_delay;
    B7_current_long_delay = start - B7_recent_long_delay;
    B8_current_long_delay = start - B8_recent_long_delay;
     
  long total_B1 =  B1_Touch.capacitiveSensor(30);
    long total_B2 =  B2_Touch.capacitiveSensor(30);
    long total_B3 =  B3_Touch.capacitiveSensor(30);
    long total_B4 =  B4_Touch.capacitiveSensor(30);
    long total_B5 =  B5_Touch.capacitiveSensor(30);
    long total_B6 =  B6_Touch.capacitiveSensor(30);
    long total_B7 =  B7_Touch.capacitiveSensor(30);
    long total_B8 =  B8_Touch.capacitiveSensor(30);
    //Single touch UUID: 0:B1 1:B2 2:B3 3:B4 4:B5 5:B6

    /** B1 TOUCH **/
    if (total_B1 > 30000 && !B1_Touch_started) {
      B1_Touch_begin = start;
      B1_recent_long_delay = start;
      B1_current_long_delay = start - B1_recent_long_delay;
      B1_Touch_started = true;
    }

    if (total_B1 < 500 && B1_Touch_started) {
      if (current_B1_delay < long_touch) {
        Serial.println("SHORT B1");
        touch = 0;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B1_Touch_started = false;
      B1_LONG_TOUCH = 0;
    }

    if (total_B1 > 30000 && B1_Touch_started && B1_current_long_delay >= long_touch) {
      Serial.println("LONG B1 +1 UNIT");
      B1_recent_long_delay = start;
      B1_LONG_TOUCH += 1;
      pCharB1_LONG_TOUCH->setValue(&B1_LONG_TOUCH, 1);
      pCharB1_LONG_TOUCH->notify();
    }

    /** B2 TOUCH **/
    if (total_B2 > 30000 && !B2_Touch_started) {
      B2_Touch_begin = start;
      B2_recent_long_delay = start;
      B2_current_long_delay = start - B2_recent_long_delay;
      B2_Touch_started = true;
    }

    if (total_B2 < 500 && B2_Touch_started) {
      if (current_B2_delay < long_touch) {
        Serial.println("SHORT B2");
        touch = 1;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B2_Touch_started = false;
      B2_LONG_TOUCH = 0;
    }

    if (total_B2 > 30000 && B2_Touch_started && B2_current_long_delay >= long_touch) {
      Serial.println("LONG B2 +1 UNIT");
      B2_recent_long_delay = start;
      B2_LONG_TOUCH += 1;
      pCharB2_LONG_TOUCH->setValue(&B2_LONG_TOUCH, 1);
      pCharB2_LONG_TOUCH->notify();
    }

    /** B3 TOUCH **/
    if (total_B3 > 30000 && !B3_Touch_started) {
      B3_Touch_begin = start;
      B3_recent_long_delay = start;
      B3_current_long_delay = start - B3_recent_long_delay;
      B3_Touch_started = true;
    }

    if (total_B3 < 500 && B3_Touch_started) {
      if (current_B3_delay < long_touch) {
        Serial.println("SHORT B3");
        touch = 2;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B3_Touch_started = false;
      B3_LONG_TOUCH = 0;
    }

    if (total_B3 > 30000 && B3_Touch_started && B3_current_long_delay >= long_touch) {
      Serial.println("LONG B3 +1 UNIT");
      B3_recent_long_delay = start;
      B3_LONG_TOUCH += 1;
      pCharB3_LONG_TOUCH->setValue(&B3_LONG_TOUCH, 1);
      pCharB3_LONG_TOUCH->notify();
    }
 
    /** B4 TOUCH **/
    if (total_B4 > 30000 && !B4_Touch_started) {
      B4_Touch_begin = start;
      B4_recent_long_delay = start;
      B4_current_long_delay = start - B4_recent_long_delay;
      B4_Touch_started = true;
    }

    if (total_B4 < 500 && B4_Touch_started) {
      if (current_B4_delay < long_touch) {
        Serial.println("SHORT B4");
        touch = 3;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B4_Touch_started = false;
      B4_LONG_TOUCH = 0;
    }

    if (total_B4 > 30000 && B4_Touch_started && B4_current_long_delay >= long_touch) {
      Serial.println("LONG B4 +1 UNIT");
      B4_recent_long_delay = start;
      B4_LONG_TOUCH += 1;
      pCharB4_LONG_TOUCH->setValue(&B4_LONG_TOUCH, 1);
      pCharB4_LONG_TOUCH->notify();
    }

    /** B5 TOUCH **/
    if (total_B5 > 30000 && !B5_Touch_started) {
      B5_Touch_begin = start;
      B5_recent_long_delay = start;
      B5_current_long_delay = start - B5_recent_long_delay;
      B5_Touch_started = true;
    }

    if (total_B5 < 500 && B5_Touch_started) {
      if (current_B5_delay < long_touch) {
        Serial.println("SHORT B5");
        touch = 4;
        pTouch->setValue(&touch, 1);
        pTouch->notify();
      }
      B5_Touch_started = false;
      B5_LONG_TOUCH = 0;
    }

    if (total_B5 > 30000 && B5_Touch_started && B5_current_long_delay >= long_touch) {
      Serial.println("LONG B5 +1 UNIT");
      B5_recent_long_delay = start;
      B5_LONG_TOUCH += 1;
      pCharB5_LONG_TOUCH->setValue(&B5_LONG_TOUCH, 1);
      pCharB5_LONG_TOUCH->notify();
    }

    /** B6 TOUCH **/
    if (total_B6 > 30000 && !B6_Touch_started) {
      B6_Touch_begin = start;
      B6_recent_long_delay = start;
      B6_current_long_delay = start - B6_recent_long_delay;
      B6_Touch_started = true;
    }

    if (total_B6 < 500 && B6_Touch_started) {
      if (current_B6_delay < long_touch) {
        Serial.println("SHORT B6");
        touch = 5;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B6_Touch_started = false;
      B6_LONG_TOUCH = 0;
    }

    if (total_B6 > 30000 && B6_Touch_started && B6_current_long_delay >= long_touch) {
      Serial.println("LONG B6 +1 UNIT");
      B6_recent_long_delay = start;
      B6_LONG_TOUCH += 1;
      pCharB6_LONG_TOUCH->setValue(&B6_LONG_TOUCH, 1);
      pCharB6_LONG_TOUCH->notify();
    }

     /** B7 TOUCH **/
   /* if (total_B7 > 15000 && !B7_Touch_started) {
      B7_Touch_begin = start;
      B7_recent_long_delay = start;
      B7_current_long_delay = start - B7_recent_long_delay;
      B7_Touch_started = true;
    }

    if (total_B7 < 500 && B7_Touch_started) {
      if (current_B7_delay < long_touch) {
        //resetLights();
        Serial.println("SHORT B7");
        touch = 6;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B7_Touch_started = false;
      B7_LONG_TOUCH = 0;
    }

    if (total_B7 > 15000 && B7_Touch_started && B7_current_long_delay >= long_touch) {
      Serial.println("LONG B7 +1 UNIT");
      B7_recent_long_delay = start;
      B7_LONG_TOUCH += 1;
      pCharB7_LONG_TOUCH->setValue(&B7_LONG_TOUCH, 1);
      pCharB7_LONG_TOUCH->notify();
    }

    /** B8 TOUCH **/
   /* if (total_B8 > 30000 && !B8_Touch_started) {
      B8_Touch_begin = start;
      B8_recent_long_delay = start;
      B8_current_long_delay = start - B8_recent_long_delay;
      B8_Touch_started = true;
    }

    if (total_B8 < 500 && B8_Touch_started) {
      if (current_B8_delay < long_touch) {
        //resetLights();
        Serial.println("SHORT B8");
        touch = 7;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B8_Touch_started = false;
    }

    if (total_B8 > 30000 && B8_Touch_started && B8_current_long_delay >= long_touch) {
      Serial.println("LONG B8 +1 UNIT");
      // Cannot add stories for this building.
    }*/

    /** B7 TOUCH **/
    if (total_B7 > 30000 && !B7_Touch_started) {
      B7_Touch_begin = start;
      B7_recent_long_delay = start;
      B7_current_long_delay = start - B7_recent_long_delay;
      B7_Touch_started = true;
    }

    if (total_B7 < 500 && B7_Touch_started) {
      if (current_B7_delay < long_touch) {
        Serial.println("SHORT B7");
        touch = 6;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B7_Touch_started = false;
      B7_LONG_TOUCH = 0;
    }

    if (total_B7 > 30000 && B7_Touch_started && B7_current_long_delay >= long_touch) {
      Serial.println("LONG B7 +1 UNIT");
      B7_recent_long_delay = start;
      B7_LONG_TOUCH += 1;
      pCharB7_LONG_TOUCH->setValue(&B7_LONG_TOUCH, 1);
      pCharB7_LONG_TOUCH->notify();
    }

  /** B8 TOUCH **/
    if (total_B8 > 30000 && !B8_Touch_started) {
      B8_Touch_begin = start;
      B8_recent_long_delay = start;
      B8_current_long_delay = start - B8_recent_long_delay;
      B8_Touch_started = true;
    }

    if (total_B8 < 500 && B8_Touch_started) {
      if (current_B8_delay < long_touch) {
        Serial.println("SHORT B8");
        touch = 7;
        pTouch->setValue(&touch, 1);
        pTouch->notify();                
      }
      B8_Touch_started = false;
      B8_LONG_TOUCH = 0;
    }

    if (total_B8 > 30000 && B8_Touch_started && B8_current_long_delay >= long_touch) {
      Serial.println("LONG B8 +1 UNIT");
      B8_recent_long_delay = start;
      B8_LONG_TOUCH += 1;
      pCharB8_LONG_TOUCH->setValue(&B8_LONG_TOUCH, 1);
      pCharB6_LONG_TOUCH->notify();
    }

    
    delay(80);
  }
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
    turnOff();
    firstCon = true;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}


// Fill specific dots at the same time with a specific color
void colorPixels(RgbColor c, String strip) {
   if (strip == "B1") {
      for (uint32_t j = 0; j < COUNT; j++) {
        B1_strip.SetPixelColor(j, c);
      }
      delay(1);
      B1_strip.Show();
   } else if (strip == "B2") {    
      for (uint32_t j = 0; j < COUNT; j++) {
        B2_strip.SetPixelColor(j, c);
      }
      delay(1);
      B2_strip.Show();
    }
    else if (strip == "B4") {    
      for (uint32_t j = 0; j < COUNT; j++) {
        B4_strip.SetPixelColor(j, c);
      }
      delay(1);
      B4_strip.Show();
    }
   else if (strip == "B6") {    
      for (uint32_t j = 0; j < COUNT; j++) {
        B6_strip.SetPixelColor(j, c);
      }
      delay(1);
      B6_strip.Show();
   } 
}

// Turn off all Pixels in the all strips
void turnOff() {
  // for all strips, turn all pixels black
  for (uint32_t i = 0; i < 6; i++) {
    for (uint32_t j = 0; j < COUNT; j++) {
      LEDs_STRIP[i].SetPixelColor(j, black);
    }
    delay(1);
    LEDs_STRIP[i].Show(); 
  } 
}
