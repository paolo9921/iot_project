#include "PANCoordinator.h"
#include "printf.h"

configuration PANCoordinatorAppC{}
implementation {

	components MainC, PANCoordinatorC as App;
	components new AMSenderC(AM_PUBSUB_MSG);
	components new AMReceiverC(AM_PUBSUB_MSG);
 	components ActiveMessageC;
 	
	components new QueueC(queue_msg_t, MSG_QUEUE_SIZE) as Queue1;
	//components new QueueC(uint16_t, MSG_QUEUE_SIZE) as Queue2;
	
 	App.Boot -> MainC.Boot;

 	 	
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Packet -> AMSenderC;

	App.MsgQueue -> Queue1;
	//App.DestQueue -> Queue2;

	
	components SerialPrintfC;
	components SerialStartC;
	
}

