
/*
*	IMPORTANT:
*	The code will be avaluated based on:
*		Code design  
*
*/
 
 
#include "Timer.h"
#include "printf.h"
#include "../LwPubSubMsgs.h"


#define PAN_C 9

module MoteC @safe() {
  uses {
  
    /****** INTERFACES *****/
	
	//boot interface
   	interface Boot;
 
        //interfaces for communication
	interface Packet;
	interface AMSend;
	interface Receive;
	interface PacketAcknowledgements as Acks;
	interface SplitControl as AMControl;	

	//interface for timers
	interface Timer<TMilli> as Timer0;
	interface Timer<TMilli> as Timer1;
        
	//other interfaces, if needed
  }
}

implementation {

	enum msg_type {CONNECT = 0, SUBSCRIBE, PUBLISH};
	enum topics {TEMPERATURE = 0, HUMIDITY, LUMONISITY};

	message_t packet;
	bool locked = FALSE;  	
	
	bool connect_ack = FALSE;
	
	uint8_t new_topic;
	bool sub_ack = FALSE;


	//prototype of functions
	bool actual_send(uint16_t address, message_t* packet);	
	
	bool actual_send (uint16_t address, message_t* packet){

                /*
                * Implement here the logic to perform the actual send of the packet using the tinyOS interfaces
                */

                if (!locked){
                        if (call AMSend.send(address, packet, sizeof(pub_sub_msg_t)) == SUCCESS){
				locked = TRUE;
			}
                }

                return locked;
        }

	
	void connect(){
                pub_sub_msg_t* connect_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));
		
		printf("Trying to connect...\n");
		printfflush();
	
                connect_msg->type = CONNECT;
		connect_msg->sender = TOS_NODE_ID;
		
		call Acks.requestAck(&packet);
		actual_send(PAN_C, &packet);
		call Timer0.startOneShot(5*1000);
                
		return;
        }

	
	void subscribe(uint8_t topic){
                pub_sub_msg_t* sub_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));
		new_topic = topic;

                printf("Trying to subscribe...\n");
                printfflush();

                sub_msg->type = SUBSCRIBE;
                sub_msg->sender = TOS_NODE_ID;
		sub_msg->topic = topic;

                call Acks.requestAck(&packet);
                actual_send(PAN_C, &packet);
                return;
        }


	event void Boot.booted(){
		printf("Starting node: %u\n", TOS_NODE_ID);
		printfflush();
		call AMControl.start();	
	}

	
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			printf("Radio successfully started\n");
			printfflush();
			connect();
			return;
		} else {	
			call AMControl.start();
		}
	}

	
	event void AMControl.stopDone(error_t err) { }

	
	event void Timer0.fired() {
		//if the connect message was acknoledged then return
		
		//the connect message was lost, try retransmission
		if (!connect_ack)	
			connect();
		else if (!sub_ack)
			subscribe(new_topic);
	}

	
	event void Timer1.fired() {
		//the node is connected and now it is going to subscribe to a topic
		new_topic = TEMPERATURE;
		subscribe(TEMPERATURE);
		call Timer0.startOneShot(5*1000);
	}


	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		/* This event is triggered when a message is sent 
		*  Check if the packet is sent 
		*/

		pub_sub_msg_t* sent_msg = (pub_sub_msg_t *) call Packet.getPayload(bufPtr, sizeof(pub_sub_msg_t));
		
		if ( sent_msg->type == CONNECT && call Acks.wasAcked(bufPtr)){
			printf("Successfully connected\n");
			connect_ack = TRUE;
			call Timer1.startOneShot(2*1000);

		} else if( sent_msg->type == SUBSCRIBE && call Acks.wasAcked(bufPtr)){
                        printf("Successfully subscribed\n");
                        sub_ack = TRUE;
			new_topic = -1;
                }

  		if (&packet == bufPtr)
			locked = FALSE;
		
		printfflush();
	}

	
	event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {

		return bufPtr;
	}
}
