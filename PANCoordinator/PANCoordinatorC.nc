#include "PANCoordinator.h"
#include "printf.h"

#define NUM_NODE 8

module PANCoordinatorC {
	uses{
	
		/****** INTERFACES *****/

		//Boot interface
		interface Boot;

		//Radio interface
		interface Packet;
		interface Receive;
		interface AMSend;
		interface SplitControl as AMControl;

		//Message queue interface
		interface Queue<queue_msg_t> as MsgQueue;
	}
}

implementation {
	//variable to be used for sending messages
	message_t packet;
	
	//array that keeps track of information on each node connection and subscription
	node_info nodes[NUM_NODE] = {};
	
	//variable to correctly manage the radio
	bool locked;
	
	uint8_t i,j;
	

	//PROTOTYPES OF FUNCTIONS
	bool actual_send(uint16_t address, message_t* packet);
	void send_publish();
	
	
  	event void Boot.booted() {
    	call AMControl.start();
  	}

	event void AMControl.startDone(error_t err) {
	
		if (err == SUCCESS) {
			for (i=0; i<NUM_NODE; i++){
				nodes[i].connected = FALSE;

				printf("Nodes %u not connected = %u\n", i, nodes[i].connected);
				printfflush();

				for(j=0; j<3; j++)
					nodes[i].topics[j] = FALSE;
			}

			printf("Node connections and topics initialized to FALSE\n");
			printfflush();
	
			return;
		} else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}
	
	
	//This method is responsible for forwarding publications to nodes.
	//In particular it pops out the head of the queue (in which all PUBLISH message to be forwarded are pushed)
	// and properly prepares the destination node and the packet to be sent.
	void send_publish(){
		queue_msg_t dequeued = (queue_msg_t) call MsgQueue.dequeue();
		pub_sub_msg_t* to_send = (pub_sub_msg_t *) call Packet.getPayload(&packet, PUB_SUB_MSG_SIZE);
		
		to_send->type = dequeued.type;
		to_send->sender = dequeued.sender;
		to_send->topic = dequeued.topic;
		to_send->payload = dequeued.payload;

		printf("Sending message, with dest:%d, message_payload: type=%d, sender=%d, topic=%d, payload=%d\n", dequeued.dest, to_send->type, to_send->sender, to_send->topic, to_send->payload);
      printfflush();

		actual_send(dequeued.dest, &packet);
	}
	

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		
		if (len == PUB_SUB_MSG_SIZE) {
			pub_sub_msg_t* recv_msg = (pub_sub_msg_t*)payload;
		
			if (recv_msg->type == CONNECT){
				//when receive a CON msg, send CONNACK (implicit) and mark this node as connected
				printf("Received CONNECT msg from %d\n",recv_msg->sender);
				printfflush();

				nodes[recv_msg->sender-2].connected = TRUE;
			} else if (recv_msg->type == SUBSCRIBE && nodes[recv_msg->sender-2].connected) {
				//when receive a SUB msg, from a connected node, send SUBACK (implicit) and mark this node subscribed to the corresponding topic
				printf("Received SUBSCRIBE msg from %d, to topic: %d\n",recv_msg->sender, recv_msg->topic);
				printfflush();

				//the node is connected, update its topic subscription
				nodes[recv_msg->sender-2].topics[recv_msg->topic] = TRUE;
					
				//debug topic list for the node
				for(i=0;i<3;i++){
					printf("node[%u].topic[%u] = %u\n", recv_msg->sender,i, nodes[recv_msg->sender-2].topics[i]);
					printfflush();
				}	
				
			} else if (recv_msg->type == PUBLISH && nodes[recv_msg->sender-2].connected) {
				// When receive a PUB msg from a connected node the PANC will:
				// 	- check to which node to forward, enqueuing messages;
				// 	- start sending them if the radio is free.
				// Enqueuing is required in order to handle multiple concurrent publications that reach the PANC 
				// while it is still finishing forwarding messages of a past publication.
				
				queue_msg_t to_enqueue;

				printf("Received PUBLISH msg\tfrom %u\ttopic:%u\tpayload:%u\n",recv_msg->sender,recv_msg->topic, recv_msg->payload);
				printfflush();
				
				// Checking which nodes need to receive the publication and enque the correct values
				for (i=0; i<NUM_NODE; i++){
					if (nodes[i].topics[recv_msg->topic]){
						
						// Preparing values to be enqueued by copying them in a proper struct
						to_enqueue.dest = i+2;
						to_enqueue.type = recv_msg->type;
						to_enqueue.sender = recv_msg->sender;
						to_enqueue.topic = recv_msg->topic;
						to_enqueue.payload = recv_msg->payload;

						if ((call MsgQueue.enqueue(to_enqueue)) == SUCCESS){
							printf("Enqueued message, with dest:%d, message_payload: type: %d, sender: %d, topic: %d, payload: %d\n", to_enqueue.dest, to_enqueue.type, to_enqueue.sender, to_enqueue.topic, to_enqueue.payload);
							printfflush();
						}
						else {
							printf("Error in enqueueing message\n");
							printfflush();
						} 
					}
				}
				
				if (call MsgQueue.empty() == FALSE && locked == FALSE){
					// There is at least one PUB message in the queue to be forwarded AND the radio is free,
					//  so we can start forwarding the just received publication
					send_publish();	
				}
			}
		}
	
		return bufPtr;
	}
	

	bool actual_send (uint16_t address, message_t* packet){

		if (!locked){
			if (call AMSend.send(address, packet, PUB_SUB_MSG_SIZE) == SUCCESS){
				locked = TRUE;

				printf("Locking the radio, sending msg...\n");
				printfflush();
			}
		}

		return locked;	  
	}
  
  
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {

		if (&packet == bufPtr){
			locked = FALSE;

			printf("Send done, unlocking the radio\n");
			printfflush();
			
			if (call MsgQueue.empty() == FALSE){
				//there is at least one message in the queue to be forwarded
				send_publish();
			}
		}	
	}

}
