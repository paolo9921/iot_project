#include "LwPubSubMsgs.h"

#define CONNECT 0
#define SUBSCRIBE 1
#define PUBLISH 2

#define NUM_NODE 7

module PANCoordinatorC {
	uses{
	
		interface Boot;
		interface Packet;
		interface Receive;
		interface AMSend;
		interface SplitControl as AMControl;
	}
}

implementation {

	message_t packet;
	
	node_info nodes[NUM_NODE] = {};
	

  	event void Boot.booted() {
    	call AMControl.start();
  	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
		  call MilliTimer.startPeriodic(250);
		}
		else {
		  call AMControl.start();
		}
	  }

	event void AMControl.stopDone(error_t err) {
		// do nothing
	  }


	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
	
	
	if (len == sizeof(pub_sub_msg_t) {
		pub_sub_msg_t* recv_msg = (pub_sub_msg_t*)payload;
		
		// when receive a CON msg, send CONNACK and mark this node as connected
		if (recv_msg->type == CONNECT){
			nodes[recv_msg->sender].connected = 1;
		}
		
		else if (recv_msg->type == SUBSCRIBE){
			
			//the node is connected, update its topic subscription
			if (nodes[recv_msg->sender].connected){
				
				nodes[recv_msg->sender].topics[recv_msg->topic] = 1;
			
			}
				
		}
	
	}
	
	
	
	bool actual_send (uint16_t address, message_t* packet){

	if (!locked){
		queued_packet = *packet;
		dbg("pan_coordinator_send", "Sending packet to node %hu\n", address);	
		if (call AMSend.send(address, &queued_packet, sizeof(radio_route_msg_t)) == SUCCESS)
			locked = TRUE;
	}
	return locked;	  
  }
	
	  
	  


	  
}



