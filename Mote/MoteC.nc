#include "Timer.h"
#include "printf.h"
#include "../LwPubSubMsgs.h"


#define PAN_C 1
#define MAX_INTERVAL 20

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

	//variables for correct usage of radio
	message_t packet;
	bool locked = FALSE;  	

	//variable to keep track of receiving the CONNACK message
	bool connect_ack = FALSE;

	uint8_t new_topic = 0;
	bool sub_ack = FALSE;
	uint8_t subLeft;

	//variables to handle publications: respectively the period and the topic of publications
	uint16_t interval;
	uint16_t pub_topic;


	//prototype of functions
	void connect();
	void subscribe(uint8_t topic);
	void publish(uint8_t topic, uint16_t payload);
	bool actual_send(uint16_t address, message_t* packet);

	
	// Function that handle mote connection
	void connect() {
    	pub_sub_msg_t* connect_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, PUB_SUB_MSG_SIZE);
		
		printf("Trying to connect...\n");
		printfflush();

      connect_msg->type = CONNECT;
		connect_msg->sender = TOS_NODE_ID;
		
		// It sets that for this packet an ack is required
		call Acks.requestAck(&packet);
	
		actual_send(PAN_C, &packet);
		
		// Start Timer0, responsible for signaling that something went wrong while attempting to connect,
		//  either the CONNECT or the CONNACK message were lost or never received.
		call Timer0.startOneShot(TIME_TO_LOSS);
                
		return;
	}

	
	// Function responsible for subscription of the mote to the topic passed as argument
	void subscribe(uint8_t topic) {
		pub_sub_msg_t* sub_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, PUB_SUB_MSG_SIZE);

		printf("Trying to subscribe to topic %u...\n", topic);
		printfflush();

		sub_msg->type = SUBSCRIBE;
		sub_msg->sender = TOS_NODE_ID;
		sub_msg->topic = topic;

		// It sets that for this packet an ack is required
		call Acks.requestAck(&packet);

		actual_send(PAN_C, &packet);

		// Start Timer0, responsible for signaling that something went wrong while attempting to connect,
		//  either the SUBSCRIBE or the SUBACK message were lost or never received.
		call Timer0.startOneShot(TIME_TO_LOSS);

		return;
	}

	
	// Function responsible for sending a new PUBLISH message
	void publish(uint8_t topic, uint16_t payload) {
		pub_sub_msg_t* pub_msg = (pub_sub_msg_t*) call Packet.getPayload(&packet, PUB_SUB_MSG_SIZE);

		printf("Publishing on topic: %u, payload: %u, with QoS=0\n", topic, payload);
		printfflush();

		pub_msg->type = PUBLISH;
		pub_msg->sender = TOS_NODE_ID;
		pub_msg->topic = topic;
		pub_msg->payload = payload;

		// Since QoS=0 no ack is required, neither Timer0 is set to fire.
		actual_send(PAN_C, &packet); 
	}


	event void Boot.booted(){
		printf("Starting node: %u\n", TOS_NODE_ID);
		printfflush();

		//Starting the radio
		call AMControl.start();	
	}


	event void Timer0.fired() {

		if (!connect_ack){
			// something went wrong when connecting, so retransmission of connect message
			connect();
		} else if (!sub_ack){
			subscribe(new_topic);
		}
	}

	
	event void Timer1.fired() {
		//the node is connected and now it is going to subscribe to a topic
		subscribe(new_topic);
	}

	
	event void Timer2.fired() {
		//it is going to publish to topic TOS_NODE_ID % 3, a random value between 1 and 100
		publish(pub_topic, (call Random.rand16() % 100)+1);
   }

	
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			
			printf("Radio successfully started\n");
			printfflush();

			//Connecting the node to PANC
			connect();

			//node 3,6,9 subscribe to all 3 topics
			if(TOS_NODE_ID % 3 == 0){
				subLeft = 3;
			}
			//node 4, 7 subscribe to 2 topics (0,1)
			else if(TOS_NODE_ID % 3 == 1){
				subLeft = 2;
			}
			//node 2,5,8 subscribe to 1 topic (2)
			else {
				subLeft = 1;
				new_topic = 2;
			}
			
			return;
		} else {	
			call AMControl.start();
		}
	}

	
	event void AMControl.stopDone(error_t err) { }


	bool actual_send (uint16_t address, message_t* packet){
                
    	if (!locked){
        	if (call AMSend.send(address, packet, PUB_SUB_MSG_SIZE) == SUCCESS){
				locked = TRUE;
			}
      }

		return locked;
	}


	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		pub_sub_msg_t* sent_msg = (pub_sub_msg_t *) call Packet.getPayload(bufPtr, PUB_SUB_MSG_SIZE);
		
		//If the sent message was a CONNECT message and it was properly acknowledged by the broker
		if ( sent_msg->type == CONNECT && call Acks.wasAcked(bufPtr) ){
			printf("Successfully connected\n");
			printfflush();

			//The connection went ok, Timer0 can be stopped
			connect_ack = TRUE;
			call Timer0.stop();

			//Start Timer1 so that after 2 seconds motes can start subscribing to topics
			call Timer1.startOneShot(2*1000);

			//After connecting each node is going to define their PUB specifications:
			//  - frequency of publication, namely the interval;
			//  - the topic of publication.
			interval = ((call Random.rand16() % MAX_INTERVAL)+1)*1000;
			pub_topic = TOS_NODE_ID % 3;

			printf("Publish interval: %u\n", interval);
			printfflush();
						
			// Starting the timer responsible for periodic publications
			call Timer2.startPeriodic(interval);

		} 
		//If the sent message was a SUBSCRIBE message and it was properly acknowledged by the broker
		else if( sent_msg->type == SUBSCRIBE && call Acks.wasAcked(bufPtr) ) {
			printf("Successfully subscribed to topic %u\n", sent_msg->topic);
			printfflush();

			//The subscription was successful, so we stop timer0, set sub_ack, decreas the counter for subscriptions
			call Timer0.stop();
			sub_ack = TRUE;
			subLeft--;

			//Check if there are subscription left, if so:
			//  - set the topic to subscribe to;
			//  - set the control variabl sub_ack to FALSE;
			//  - delay subscription after 0.5 seconds
			if(subLeft > 0){
				new_topic++;
				sub_ack = FALSE;
				call Timer1.startOneShot(500);
			}
      } 	

		//Freeing the radio locked variable for new messages
  		if (&packet == bufPtr)
			locked = FALSE;

	}


	//When receiving messages the mote is not asked to do nothing, we are just printing the received message for debugging
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		
		if (len == PUB_SUB_MSG_SIZE) {
			pub_sub_msg_t* recv_msg = (pub_sub_msg_t*) payload;

			printf("Received message, type: %u, sender: %u, topic: %u, payload: %u\n", recv_msg->type, recv_msg->sender, recv_msg->topic, recv_msg->payload);
			printfflush();
		}

		return bufPtr;
	}
}
