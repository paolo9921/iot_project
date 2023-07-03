#include "Timer.h"
#include "printf.h"
#include "../LwPubSubMsgs.h"


#define PAN_C 1


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
	interface Timer<TMilli> as Timer2;

	//interface for randomness
	interface Random;
  }
}

implementation {

	message_t packet;
	bool locked = FALSE;  	
	
	bool connect_ack = FALSE;
	
	uint8_t new_topic;
	bool sub_ack = FALSE;
	
	uint8_t nSub;
	uint8_t totSub;
	
	uint16_t interval;


	//prototype of functions
	void connect();
	void subscribe(uint8_t topic);
	void publish(uint8_t topic, uint16_t payload);
	bool actual_send(uint16_t address, message_t* packet);


	
	
	bool actual_send (uint16_t address, message_t* packet){
                
    	if (!locked){
        	if (call AMSend.send(address, packet, sizeof(pub_sub_msg_t)) == SUCCESS){
				locked = TRUE;
			}
        }

		return locked;
	}

	
	void connect() {
    	pub_sub_msg_t* connect_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));
		
		//printf("Trying to connect...\n");
		printfflush();
	
        connect_msg->type = CONNECT;
		connect_msg->sender = TOS_NODE_ID;
		
		printf("send connection\n");
		printfflush();
		
		call Acks.requestAck(&packet);
		actual_send(PAN_C, &packet);
		
		call Timer0.startOneShot(TIME_TO_LOSS * 1000);
                
		return;
	}

	
	void subscribe(uint8_t topic) {
		pub_sub_msg_t* sub_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));
		// new_topic = topic;

		printf("my Id: %u.Trying to subscribe to topic %u\n", TOS_NODE_ID, topic);
		printfflush();

		sub_msg->type = SUBSCRIBE;
		sub_msg->sender = TOS_NODE_ID;
		sub_msg->topic = topic;

		call Acks.requestAck(&packet);
		actual_send(PAN_C, &packet);
		return;
	}

	
	void publish(uint8_t topic, uint16_t payload) {
		pub_sub_msg_t* pub_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));

		printf("Publishing on topic: %u with QoS=0\n", topic);
		printfflush();

		pub_msg->type = PUBLISH;
		pub_msg->sender = TOS_NODE_ID;
		pub_msg->topic = topic;
		pub_msg->payload = payload;

		actual_send(PAN_C, &packet); 
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
			nSub = 0;
			
			
			//node 3,6,9 subscribe to all 3 topics
			if(TOS_NODE_ID % 3 == 0){
				totSub = 3;
				new_topic = 0;
			}
			//node 4, 7 subscribe to 2 topics (0,1)
			else if(TOS_NODE_ID % 3 == 1){
				totSub = 2;
				new_topic = 0;
			}
			//node 2,5,8 subscribe to 1 topic (2)
			else {
				totSub = 1;
				new_topic = 2;
			}
			
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
		else if (!sub_ack){
			subscribe(new_topic);
		}
	}

	
	event void Timer1.fired() {
		//the node is connected and now it is going to subscribe to a topic
		
		//printf("sending new subscribe to topic: %u\n",new_topic);
		//printfflush();
		subscribe(new_topic);
		call Timer0.startOneShot(5*1000);
		
	}

	
	event void Timer2.fired() {
        	//it is going to publish to a random topic, a random value
	        publish(call Random.rand16() % 3, call Random.rand16() % 100 +1 );
    	    
    	}


	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		/* This event is triggered when a message is sent 
		*  Check if the packet is sent 
		*/

		pub_sub_msg_t* sent_msg = (pub_sub_msg_t *) call Packet.getPayload(bufPtr, sizeof(pub_sub_msg_t));
		
		if ( sent_msg->type == CONNECT && call Acks.wasAcked(bufPtr)){
			printf("Successfully connected\n");
			printfflush();
			connect_ack = TRUE;
			call Timer1.startOneShot(2*1000);

			// si puo anche mettere tutto dentro a startOneShot ma cosi mi stampavo interval
                        interval = ((call Random.rand16() % 20)+1)*1000;
                        printf("node: %u next publish (interval) : %u\n", TOS_NODE_ID, interval);
                        printfflush();
                                
                        call Timer2.startPeriodic(interval);

		} else if( sent_msg->type == SUBSCRIBE && call Acks.wasAcked(bufPtr)){
            printf("Successfully subscribed to topic %u, new_topic = %u\n", sent_msg->topic, new_topic);
            printfflush();
            sub_ack = TRUE;
            
            nSub++;
            if(nSub < totSub){
            	new_topic++;
              	call Timer1.startOneShot(500);
            }
        } 	

  		if (&packet == bufPtr)
			locked = FALSE;
		
		printfflush();
	}

	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		
		if (len == sizeof(pub_sub_msg_t)) {
			pub_sub_msg_t* recv_msg = (pub_sub_msg_t*) payload;
			printf("Received message, type: %u, from: %u, topic: %u, payload: %u\n", recv_msg->type, recv_msg->sender, recv_msg->topic, recv_msg->payload);
			printfflush();
		}

		return bufPtr;
	}
}
