#include "printf.h"
#include "../LwPubSubMsgs.h"


configuration MoteAppC {}

implementation {
  
  /****** COMPONENTS *****/
  components MainC, MoteC as App;
  
  components new AMSenderC(AM_PUBSUB_MSG);
  components new AMReceiverC(AM_PUBSUB_MSG);
  components ActiveMessageC;  

  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  
  components RandomC;

  /****** INTERFACES *****/
  
  //Boot interface
  App.Boot -> MainC.Boot;
  
  //Radio interface
  App.Packet -> AMSenderC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;  
  App.Acks -> AMSenderC.Acks;

  //Timer interface
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  App.Timer2 -> Timer2;


  //Random interface
  App.Random -> Random;

  
  //Debug interface
  components SerialPrintfC;
  components SerialStartC;

}


