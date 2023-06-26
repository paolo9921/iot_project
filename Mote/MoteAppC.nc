
 
#include "../LwPubSubMsgs.h"


configuration MoteAppC {}

implementation {
  
  /****** COMPONENTS *****/
  components MainC, MoteC as App;
  
  components new AMSenderC(AM_PUBSUB_MSG);
  components new AMReceiverC(AM_PUBSUB_MSG);
  components ActiveMessageC;  

  components new TimerMilliC() as Timer0; 
  
  /****** INTERFACES *****/
  
  //Boot interface
  App.Boot -> MainC.Boot;
  
  //Radio interface
  App.Packet -> AMSenderC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;  

  //Timer interface
  App.Timer0 -> Timer0;
  
  /****** Wire the other interfaces down here *****/

}


