#include <Arduino.h> 
#include <SPI.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <IFTTTWebhook.h>
//#include <CapacitiveSensor.h>


// HOME WIFI
char ssid[] = " ";    
int status = WL_IDLE_STATUS; 
char pass[] = " "; 
// iPhone socket
const uint16_t port = 8080;
const char * host = "127.0.0.1";
//const char * host = "192.168.2.106";
// Eduroam WIFI
/*char ssid[] = "TBA";    
int status = WL_IDLE_STATUS; 
char pass[] = "TBA"; */

WiFiServer server(80);
//WiFiClient client;
#define LED_G 13
#define LED_Y 12
#define Touch_G T0 // PIN 4 on ESP32
#define Touch_Y T2 // PIN 2 on ESP32
bool green_active = false;
bool yellow_active = false;
int repetitions = 0;


void setup() {
  Serial.begin(9600);
  
 while (status != WL_CONNECTED) {
     Serial.print("Attempting to connect to Network named: ");
      Serial.println(ssid);
      delay(2000);
      status = WiFi.begin(ssid, pass);
      // wait 10 seconds for connection:
      delay(10000);
  }
  server.begin();
  printWifiStatus();
  pinMode(LED_G, OUTPUT);
  pinMode(LED_Y, OUTPUT);
  pinMode(Touch_G, INPUT);
  pinMode(Touch_Y, INPUT);
}

  void loop() {
    /*HTTPClient http;
 
    http.begin("http://jsonplaceholder.typicode.com/comments?id=10"); //Specify the URL
    int httpCode = http.GET();                                        //Make the request
 
    if (httpCode > 0) { //Check for the returning code
 
        String payload = http.getString();
        Serial.println(httpCode);
        Serial.println(payload);
      }
 
    else {
      Serial.println("Error on HTTP request");
    }
 
    http.end(); //Free the resources
 
  delay(8000);*/
   /* int touchValue_green = touchRead(Touch_G);
    int touchValue_yellow = touchRead(Touch_Y);
    repetitions += 1;
    if (touchValue_green < 13 && touchValue_green > 4  && repetitions > 8 ){
      Serial.println(touchValue_green);
      Serial.println("TOUCH GREEN DETECTED");
      repetitions = 0;
      server.write("G");
      client.write("G");
      //sendTrigger("G");
    }
    if (touchValue_yellow < 13 && touchValue_yellow > 4 && repetitions > 8 ){
      Serial.println(touchValue_yellow);
      Serial.println("TOUCH YELLOW DETECTED");
      repetitions = 0;
      server.write("Y");
      client.write("Y");
      //sendTrigger("Y");
    }
    delay(80);*/

    WiFiClient client = server.available();   // listen for incoming clients
  
    if (client) {                             // if you get a client,
      Serial.println("new client");           // print a message out the serial port
      String currentLine = "";                // make a String to hold incoming data from the client
      while (client.connected()) {            // loop while the client's connected     
        int touchValue_green = touchRead(Touch_G);
    int touchValue_yellow = touchRead(Touch_Y);
    repetitions += 1;
    Serial.println(touchValue_green);
    Serial.println(touchValue_yellow);
    if (touchValue_green < 13 && touchValue_green > 4  && repetitions > 8 ){
      Serial.println(touchValue_green);
      Serial.println("TOUCH GREEN DETECTED");
      repetitions = 0;
      server.write("G");
      client.write("G");
      //sendTrigger("G");
    }
    if (touchValue_yellow < 13 && touchValue_yellow > 4 && repetitions > 8 ){
      Serial.println(touchValue_yellow);
      Serial.println("TOUCH YELLOW DETECTED");
      repetitions = 0;
      server.write("Y");
      client.write("Y");
      //sendTrigger("Y");
    }
    delay(80);

               
        if (client.available()) {             // if there's bytes to read from the client,
          char c = client.read();             // read a byte, then
          Serial.write(c);                    // print it out the serial monitor
          if (c == '\n') {                    // if the byte is a newline character
  
            // if the current line is blank, you got two newline characters in a row.
            // that's the end of the client HTTP request, so send a response:
            if (currentLine.length() == 0) {
              // HTTP headers always start with a response code (e.g. HTTP/1.1 200 OK)
              // and a content-type so the client knows what's coming, then a blank line:
              client.println("HTTP/1.1 200 OK");
              client.println("Content-type:text/html");
              client.println();
              client.print("Click <a href=\"/G\">here</a> to test GREEN light.<br>");
              client.print("Click <a href=\"/Y\">here</a> to test YELLOW light.<br>");              
              // The HTTP response ends with another blank line:
              client.println();
              break;
            } else {
              currentLine = "";
            }
          } else if (c != '\r') {  // if you got anything else but a carriage return character,
            currentLine += c;      // add it to the end of the currentLine
          }
          handleRequests(currentLine);
        }
      }
      //client.stop();
      //Serial.println("Client disonnected");
    }
  }

    void handleRequests(String currentLine) {
    //  Check which request was send
    if (currentLine.endsWith("GET /G")) {
      Serial.print("GREEN LIGHT ON");
      digitalWrite(LED_G, HIGH);   // turn the LED on (HIGH is the voltage level)
      green_active = true;
    }
    if (currentLine.endsWith("GET /Y")) {
      Serial.print("YELLOW LIGHT ON.");
      yellow_active = true;
      digitalWrite(LED_Y, HIGH);   // turn the LED on (HIGH is the voltage level)
    }
    if (currentLine.endsWith("GET /Go")) {
      Serial.print("GREEN LIGHT OFF");      
      digitalWrite(LED_G, LOW);    // turn the LED off by making the voltage LOW  
      green_active = false;    
    }
    if (currentLine.endsWith("GET /Yo")) {
      Serial.print("YELLOW LIGHT OFF.");
      digitalWrite(LED_Y, LOW);    // turn the LED off by making the voltage LOW
      yellow_active = false;
    }
  }

void sendTrigger(String c){
/*  if (!client.connect(host, port)) {
        Serial.println("Connection to host failed");
        delay(1000);
        return;
    }
      Serial.println("Connected to server successful!");
      //client.print("Hello from ESP32!");
//      client.print(c);
      Serial.print(c);
      Serial.println(" was sent");
      Serial.println("Disconnecting...");
      //client.stop();*/
}

 void printWifiStatus() {
    Serial.print("SSID: ");
    Serial.println(WiFi.SSID());
    IPAddress ip = WiFi.localIP();
    Serial.print("IP Address: ");
    Serial.println(ip);
    long rssi = WiFi.RSSI();
    Serial.print("signal strength (RSSI):");
    Serial.print(rssi);
    Serial.println(" dBm");
    Serial.print("To see this page in action, open a browser to http://");
    Serial.println(ip);
  }

