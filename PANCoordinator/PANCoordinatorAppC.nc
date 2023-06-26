#include "LwPubSubMsgs.h"

configuration PANCoordinatorAppC{}
implementation {
	components MainC, PANCoordinatorC as App;
	components new AMSenderC(AM_RADIO_COUNT_MSG);
 	components ActiveMessageC;
 	
 	App.Boot -> MainC.Boot
 	
 	
 	components new AMReceiverC(AM_RADIO_COUNT_MSG)
 	 	
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	
}
