#include "../LwPubSubMsgs.h"
#include "printf.h"

configuration PANCoordinatorAppC{}
implementation {

	components MainC, PANCoordinatorC as App;
	components new AMSenderC(AM_PUBSUB_MSG);
	components new AMReceiverC(AM_PUBSUB_MSG);
 	components ActiveMessageC;
 	
 	App.Boot -> MainC.Boot;
 	
 	
 	 	
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Packet -> AMSenderC;
	
	components SerialPrintfC;
	components SerialStartC;
	
	components SerialActiveMessageC;
	components new SerialAMSenderC(AM_PUBSUB_MSG);
	
	App.AMSend -> SerialAMSenderC;
	App.AMControl -> SerialActiveMessageC;
	
}

