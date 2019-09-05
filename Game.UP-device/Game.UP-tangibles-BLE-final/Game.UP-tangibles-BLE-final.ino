#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLEUUID.h>
#include <TaskScheduler.h>
#include <Arduino.h>
#include <CapacitiveSensor.h>
#include <NeoPixelBus.h>

/** ============= BLUETOOTH SERVICES AND CHARACTERISTICS =============**/
/** ==================================================================**/
#define SERVICE_UUID                 "9a8ca9ef-e43f-4157-9fee-c37a3d7dc12d"
// UUIDs for controlling LEDs
#define B1_UUID                      "e94f85c8-7f57-4dbd-b8d3-2b56e107ed60"
#define B2_UUID                      "a8985fda-51aa-4f19-a777-71cf52abba1e"
#define B3_UUID                      "c8f2a025-fffb-4427-be27-d0a85c44a50d"
#define B4_UUID                      "4fde9fc5-a828-40c6-a728-3fe2a5bc88b9"
#define B5_UUID                      "5d020c58-aa45-4516-8c66-260cd5029426"
#define B6_UUID                      "ec666639-a88e-4166-a7ba-dd59a2fabfc1"
//UUIDs for Touch
#define B_TOUCH_UUID                 "19c59b3c-ad62-4c77-9b76-fb3a41041749"
#define B1_LONG_TOUCH_UUID           "7b8874ae-e467-4e8d-a142-d027e557f932"
#define B2_LONG_TOUCH_UUID           "fc2221a3-e140-4f8a-ae5f-078c26f35ba9"
#define B3_LONG_TOUCH_UUID           "0850f78f-538d-4e1b-8235-fd67acdafcd5"
#define B4_LONG_TOUCH_UUID           "455bf338-29c2-4a9f-a6ff-5fa0dfd04af9"
#define B5_LONG_TOUCH_UUID           "403828e6-6b6e-4273-9c92-3c4c13cffe0c"
#define B6_LONG_TOUCH_UUID           "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define B7_LONG_TOUCH_UUID           "967950e2-eea6-47bb-a4e5-2f14d5bd2b3d"
#define B8_LONG_TOUCH_UUID           "61a87f70-666c-483e-b297-47f9a0dd7b03"
String LEDs_UUID[] = {B1_UUID, B2_UUID , B3_UUID , B4_UUID , B5_UUID , B6_UUID};
String TOUCH_UUID[] = {B1_LONG_TOUCH_UUID, B2_LONG_TOUCH_UUID, B3_LONG_TOUCH_UUID, B4_LONG_TOUCH_UUID, B5_LONG_TOUCH_UUID, B6_LONG_TOUCH_UUID, B7_LONG_TOUCH_UUID, B8_LONG_TOUCH_UUID};
// UUIDs for device infos
#define DEVINFO_UUID              (uint16_t)0x180a
#define DEVINFO_MANUFACTURER_UUID (uint16_t)0x2a29
#define DEVINFO_NAME_UUID         (uint16_t)0x2a24
#define DEVINFO_SERIAL_UUID       (uint16_t)0x2a25
#define DEVICE_MANUFACTURER           "WROOM"
#define DEVICE_NAME                   "Marla_ESP32"
// BLE server
BLEServer* pServer = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
Scheduler scheduler;
// Char for LED
BLECharacteristic *pCharB1;
BLECharacteristic *pCharB2;
BLECharacteristic *pCharB3;
BLECharacteristic *pCharB4;
BLECharacteristic *pCharB5;
BLECharacteristic *pCharB6;
BLECharacteristic* LEDs_CHAR[] = {pCharB1, pCharB2, pCharB3, pCharB4, pCharB5, pCharB6};
// Char for touch
BLECharacteristic *pTouch;
BLECharacteristic *pCharB1_LONG_TOUCH;
BLECharacteristic *pCharB2_LONG_TOUCH;
BLECharacteristic *pCharB3_LONG_TOUCH;
BLECharacteristic *pCharB4_LONG_TOUCH;
BLECharacteristic *pCharB5_LONG_TOUCH;
BLECharacteristic *pCharB6_LONG_TOUCH;
BLECharacteristic *pCharB7_LONG_TOUCH;
BLECharacteristic *pCharB8_LONG_TOUCH;
BLECharacteristic* LONG_TOUCHs_CHAR[] = {pCharB1_LONG_TOUCH, pCharB2_LONG_TOUCH, pCharB3_LONG_TOUCH, pCharB4_LONG_TOUCH, pCharB5_LONG_TOUCH, pCharB6_LONG_TOUCH, pCharB7_LONG_TOUCH, pCharB8_LONG_TOUCH};

/** ======================= LEDs =====================================**/
/** ==================================================================**/
#define B1_LED 23
#define B2_LED 22
#define B3_LED 21
#define B4_LED 19
#define B5_LED 18
#define B6_LED 5
int LEDs_PINS[] = {B1_LED, B2_LED, B3_LED, B4_LED, B5_LED, B6_LED};
// Number of LEDs in strips
#define COUNT 2
// 220 Ohm resistor for Neopixels. 5V power from ESP32.
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B1_strip(COUNT, B1_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B2_strip(COUNT, B2_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B3_strip(COUNT, B3_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B4_strip(COUNT, B4_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B5_strip(COUNT, B5_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> B6_strip(COUNT, B6_LED);
NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> LEDs_STRIP[] = {B1_strip, B2_strip, B3_strip, B4_strip, B5_strip, B6_strip};
// Define colors to be displayed
#define colorSaturation 255
RgbColor red(colorSaturation, 0, 0);
RgbColor green(0, colorSaturation, 0);
RgbColor blue(0, 0, colorSaturation);
RgbColor black(0);
// Keep track of LED states
// OFF, BUILDING TYPE, AGE
String B1_LED_STATUS = "OFF";
String B2_LED_STATUS = "OFF";
String B3_LED_STATUS = "OFF";
String B4_LED_STATUS = "OFF";
String B5_LED_STATUS = "OFF";
String B6_LED_STATUS = "OFF";
// TODO: DELETE
bool B1_LED_ON = false;
bool B2_LED_ON = false;
bool B3_LED_ON = false;
bool B4_LED_ON = false;
bool B5_LED_ON = false;
bool B6_LED_ON = false;
// Keep track of type of highlight for B4. False for RESIDENTIAL, true for AGE
bool B4_highlight_type = false;

/** ======================= Touch ====================================**/
/** ==================================================================**/
CapacitiveSensor   B1_Touch = CapacitiveSensor(4, 32);       // 10M resistor between B1_LEDs 4 & 32, B1_LED 32 is sensor B2_LED.
CapacitiveSensor   B2_Touch = CapacitiveSensor(4, 33);       // 10M resistor between B2_LEDs 4 & 33 
CapacitiveSensor   B3_Touch = CapacitiveSensor(4, 27);       // 10M resistor between B3_LEDs 4 & 27 
CapacitiveSensor   B4_Touch = CapacitiveSensor(4, 14);       // 10M resistor between B4_LEDs 4 & 14
CapacitiveSensor   B5_Touch = CapacitiveSensor(4, 13);       // 10M resistor between B5_LEDs 4 & 13
CapacitiveSensor   B6_Touch = CapacitiveSensor(4, 0);        // 10M resistor between B6_LEDs 4 & 0
CapacitiveSensor   B7_Touch = CapacitiveSensor(4, 2);        // 10M resistor between B7_LEDs 4 & 2
CapacitiveSensor   B8_Touch = CapacitiveSensor(4, 15);       // 10M resistor between B8_LEDs 4 & 15
CapacitiveSensor TOUCH_PINS[] = {B1_Touch, B2_Touch, B3_Touch, B4_Touch, B5_Touch, B6_Touch, B7_Touch, B8_Touch};
const unsigned long long_touch = 2000;
// Current touch: 0=B1, 1=B2, 2=B3, 3=B4, 4=B5, 5=B6, 6=B7, 7=B8, 8=nothing
uint8_t touch = 8;
// 0 for no long touches, 1 for one unit of long touch where 1 unit is 700 ms. 2 for 2 units and so on.
/*uint8_t B1_LONG_TOUCH = 0;
uint8_t B2_LONG_TOUCH = 0;
uint8_t B3_LONG_TOUCH = 0;
uint8_t B4_LONG_TOUCH = 0;
uint8_t B5_LONG_TOUCH = 0;
uint8_t B6_LONG_TOUCH = 0;
uint8_t B7_LONG_TOUCH = 0;
uint8_t B8_LONG_TOUCH = 0; */
uint8_t LONG_TOUCH_STORY[] = {0, 0, 0, 0, 0, 0, 0, 0};
bool LONG_TOUCH_BOOL[] = {false, false, false, false, false, false, false, false};
/*bool B4_Touch_started = false;
bool B5_Touch_started = false;*/
unsigned long TOUCH_TIME[] = {false, false, false, false, false, false, false, false};
/*unsigned long B4_Touch_begin;
unsigned long B5_Touch_begin;*/
long CURRENT_LONG_DELAY[] = {0, 0, 0, 0, 0, 0, 0, 0};
long RECENT_LONG_DELAY[] = {0, 0, 0, 0, 0, 0, 0, 0};
/*long B4_current_long_delayy;
long B4_recent_long_delay;
long B5_current_long_delay;
long B5_recent_long_delay;*/

/** ====================== BLE CALLBACKS =============================**/
/** ==================================================================**/
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

// Handle Requests for LED
class LEDCallbacks: public BLECharacteristicCallbacks { 
  // Cannot pass LED strip for callback   
    String s;
    public:     
       LEDCallbacks(String p){
        s = p;
       }    
       
    void onWrite(BLECharacteristic *pCharacteristic) {      
      std::string value = pCharacteristic->getValue();
      uint8_t v = value[0];
      NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B1_strip;
      
      // 0: off , 1 : green, 2 :red , 3:blue 
      // Find out which strip was selected
      if (s == "B1") {
          NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B1_strip;
      } else if (s ==  "B2") {
        NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B2_strip;
      } else if (s ==  "B3") {
        NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B3_strip;
      }else if (s ==  "B4") {
        NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B4_strip;
      }else if (s ==  "B5") {
        NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B5_strip;
      }else if (s ==  "B6") {
        NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip = B6_strip;
      }
      if (v == 0){   
          Serial.print(s);
          Serial.println(" OFF");
          colorPixels(black, strip);                    
        } else if (v == 1){          
          Serial.print(s);
          Serial.println(" ON- green");         
          colorPixels(green, strip);          
        }else if (v == 2){          
          Serial.print(s);
          Serial.println("ON - red");         
          colorPixels(red, strip);          
        } else if (v == 3){          
          Serial.print(s);
          Serial.println("ON - blue");         
          colorPixels(blue, strip);          
        }else {
        Serial.println("Invalid data received");
      }
    }
  
  // Fill specific dots at the same time with a color
  void colorPixels(RgbColor c, NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip) {
   /*  switch (strip) {
      case B1_strip:
        for (uint32_t j = 0; j < COUNT; j++) {
          B1_strip.SetPixelColor(j, c);
        }
        delay(1);
        B1_strip.Show();
        break;
      case B2_strip:
        for (uint32_t j = 0; j < COUNT; j++) {
          B2_strip.SetPixelColor(j, c);
        }
        delay(1);
        B2_strip.Show();
        break;
      case B3_strip:
        for (uint32_t j = 0; j < COUNT; j++) {
          B3_strip.SetPixelColor(j, c);
        }
        delay(1);
        B3_strip.Show();
        break;
      case B4_strip:
        for (uint32_t j = 0; j < COUNT; j++) {
          B4_strip.SetPixelColor(j, c);
        }
        delay(1);
        B4_strip.Show();
        break;
      case B5_strip:
        for (uint32_t j = 0; j < COUNT; j++) {
          B5_strip.SetPixelColor(j, c);
        }
        delay(1);
        B5_strip.Show();
        break;
      case B6_strip:
        for (uint32_t j = 0; j < COUNT; j++) {
          B6_strip.SetPixelColor(j, c);
        }
        delay(1);
        B6_strip.Show();
        break;
      default:
        break;
    }*/
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting...");
  
  for (int i =0; i < 6; i++){
    pinMode(LEDs_PINS[i], OUTPUT);
  }
  
  for (int i =0; i < 8; i++){
    TOUCH_PINS[i].set_CS_AutocaL_Millis(0xFFFFFFFF);
  }
  
  for (int i =0; i < 6; i++){
    LEDs_STRIP[i].Begin();
    LEDs_STRIP[i].Show();
  }
  
  // Create the BLE Device
  String devName = "Marla_ESP32";
  String chipId = String((uint32_t)(ESP.getEfuseMac() >> 24), HEX);
  devName += '_';
  devName += chipId;
  BLEDevice::init(devName.c_str());

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create the BLE Characteristics for LED & Touch
  for (int i =0; i < 6; i++){
    LEDs_CHAR[i] = pService->createCharacteristic(&LEDs_UUID[i], BLECharacteristic::PROPERTY_READ  | BLECharacteristic::PROPERTY_WRITE);
    LEDs_CHAR[i]->setCallbacks(new LEDCallbacks(LEDs_STRIP[i]));
  }

  pTouch = pService->createCharacteristic(TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE );
  for (int = 0; i <8; i++){
    LONG_TOUCHs_CHAR[i] = pService->createCharacteristic(TOUCH_UUID[i], BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE);
  }
  
  // Start the service
  pService->start();
  pService = pServer->createService(DEVINFO_UUID);
  BLECharacteristic *pChar = pService->createCharacteristic(DEVINFO_MANUFACTURER_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_MANUFACTURER);
  pChar = pService->createCharacteristic(DEVINFO_NAME_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_NAME);
  pChar = pService->createCharacteristic(DEVINFO_SERIAL_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(chipId.c_str());

  // Advertising
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

  if (deviceConnected) {
    long start = millis();

    for (int i = 0; i <8 ; i++){
      long current_delay = start - LONG_TOUCH_TIME[i];
      CURRENT_LONG_DELAY[i] = start - RECENT_LONG_DELAY[i];
      long total =  TOUCH_PINS[i].capacitiveSensor(30);

      if (total > 30000 && !TOUCH_BOOL[i]) {
        LONG_TOUCH_TIME[i]  = start;
        RECENT_LONG_DELAY[i] = start;
        CURRENT_LONG_DELAY[i] = start - RECENT_LONG_DELAY[i];
        TOUCH_BOOL[i] = true;
      }

      if (total < 500 && TOUCH_BOOL[i]) {
        if (current_delay < long_touch) {
          Serial.println("SHORT");
          //TODO: send value for which building
          touch = 0;         
          pTouch->setValue(&touch, 1);
          pTouch->notify();
          //TODO: What is this?
          //turnOff();
          // TODO: Add processing for short touch. Where should the logic be?
          // Pay attention => there's 8 touch and 6 LEDs. 
        }
        TOUCH_BOOL[i] = false;
        LONG_TOUCH_STORY[i] = 0;
      }

      if (total > 30000 && TOUCH_BOOL[i] && CURRENT_LONG_DELAY[i] >= long_touch) {
        Serial.println("LONG B");
        Serial.print(i+1);
        Serial.print(" UNIT");
        RECENT_LONG_DELAY[i] = start;
        LONG_TOUCH_STORY[i] += 1;                
        LONG_TOUCHs_CHAR[i]->setValue(&LONG_TOUCH_STORY[i], 1);
        LONG_TOUCHs_CHAR[i]->notify();
      }
      delay(80);
    }
  }
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}

// Fill specific dots at the same time with a specific color
void colorPixels(RgbColor c, NeoPixelBus<NeoGrbFeature, NeoEsp32BitBangWs2813Method> strip) {
  // pay attention 6 and not 8
   if (strip == B1_strip) {
      for (uint32_t j = 0; j < COUNT; j++) {
        B1_strip.SetPixelColor(j, c);
      }
      delay(1);
      B1_strip.Show();
   } else if (strip == B2_strip) {    
      for (uint32_t j = 0; j < COUNT; j++) {
        B2_strip.SetPixelColor(j, c);
      }
      delay(1);
      B2_strip.Show();
    }
    case B3_strip:
      for (uint32_t j = 0; j < COUNT; j++) {
        B3_strip.SetPixelColor(j, c);
      }
      delay(1);
      B3_strip.Show();
      break;
    case B4_strip:
      for (uint32_t j = 0; j < COUNT; j++) {
        B4_strip.SetPixelColor(j, c);
      }
      delay(1);
      B4_strip.Show();
      break;
    case B5_strip:
      for (uint32_t j = 0; j < COUNT; j++) {
        B5_strip.SetPixelColor(j, c);
      }
      delay(1);
      B5_strip.Show();
      break;
    case B6_strip:
      for (uint32_t j = 0; j < COUNT; j++) {
        B6_strip.SetPixelColor(j, c);
      }
      delay(1);
      B6_strip.Show();
      break;
    default:
      break;
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
