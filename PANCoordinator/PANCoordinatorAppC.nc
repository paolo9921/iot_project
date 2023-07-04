#include "PANCoordinator.h"
#include "printf.h"


configuration PANCoordinatorAppC{}

implementation {

	/****** COMPONENTS *****/
	components MainC, PANCoordinatorC as App;

	components new AMSenderC(AM_PUBSUB_MSG);
	components new AMReceiverC(AM_PUBSUB_MSG);
 	components ActiveMessageC;
 	
	components new QueueC(queue_msg_t, MSG_QUEUE_SIZE) as Queue1;
	
	/****** INTERFACES *****/

	//Boot interface
 	App.Boot -> MainC.Boot;

	//Radio interface
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Packet -> AMSenderC;

	//Message queue interface
	App.MsgQueue -> Queue1;
	
	//Debug interface
	components SerialPrintfC;
	components SerialStartC;
}
