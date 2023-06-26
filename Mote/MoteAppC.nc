
 
#include "Mote.h"


configuration MoteAppC {}

implementation {
  
  /****** COMPONENTS *****/
  components MainC, MoteC as App;
  
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components ActiveMessageC;  

  
  
  /****** INTERFACES *****/
  
  //Boot interface
  App.Boot -> MainC.Boot;
  
  //Radio interface
  App.Packet -> AMSenderC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;  
  
  /****** Wire the other interfaces down here *****/

}


