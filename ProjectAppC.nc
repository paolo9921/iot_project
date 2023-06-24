
 
#include "RadioRoute.h"


configuration RadioRouteAppC {}
implementation {
/****** COMPONENTS *****/
  components Main as App;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components ActiveMessageC;  


  
  
  /****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;
   
  
  /****** Wire the other interfaces down here *****/

}


