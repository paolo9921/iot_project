
/*
*	IMPORTANT:
*	The code will be avaluated based on:
*		Code design  
*
*/
 
 
#include "Timer.h"
#include "Mote.h"

module MoteC @safe() {
  uses {
  
    /****** INTERFACES *****/
	
	//boot interface
   	interface Boot;
 
        //interfaces for communication
	interface Packet;
	interface AMSend;
	interface Receive;
	interface SplitControl as AMControl;	

	//interface for timers

        //other interfaces, if needed
  }
}

implementation {
	message_t packet;
	bool locked;  	


	//TODO implementation of application 
	event void Boot.booted(){
		call AMControl.start();	
	}

	
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			return;
		} else {	
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err) { }

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		/* This event is triggered when a message is sent 
		*  Check if the packet is sent 
		*/
  	}
	
	event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {

		return bufPtr;
	}
}
