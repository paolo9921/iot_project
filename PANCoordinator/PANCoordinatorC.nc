#include "PANCoordinator.h"
#include "printf.h"

#define NUM_NODE 8

module PANCoordinatorC {
	uses{
	
		interface Boot;
		interface Packet;
		interface Receive;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Queue<queue_msg_t> as MsgQueue;
	}
}

implementation {

	message_t packet;
	
	node_info nodes[NUM_NODE] = {};
	
	bool locked;
	
	uint8_t i,j;
	


	bool actual_send(uint16_t address, message_t* packet);
	
	
  	event void Boot.booted() {
    		call AMControl.start();
  	}

	event void AMControl.startDone(error_t err) {
	
		if (err == SUCCESS) {
			for (i=0; i<NUM_NODE; i++){
				nodes[i].connected = FALSE;
				printf("Nodes %u connected = %u\n", i, nodes[i].connected);
				printfflush();
				for(j=0; j<3; j++)
					nodes[i].topics[j] = FALSE;
			}

			printf("Nodes connection and topics initialized\n");
			printfflush();
	
			return;
		} 
		else 
		  call AMControl.start();
	  }

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}
	
	
	void send_publish(){
		queue_msg_t dequeued = (queue_msg_t) call MsgQueue.dequeue();
		pub_sub_msg_t* to_send = (pub_sub_msg_t *) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));
		
		*to_send = *dequeued.payload;

		printf("Sending msg to: %u, on topic:%u\n", dequeued.dest, dequeued.payload->topic);
                printfflush();

		actual_send(dequeued.dest, &packet);
	}
	

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
			
		if (len == sizeof(pub_sub_msg_t)) {
			pub_sub_msg_t* recv_msg = (pub_sub_msg_t*)payload;
		
			// when receive a CON msg, send CONNACK and mark this node as connected
			if (recv_msg->type == CONNECT){
					
				printf("Received CONNECT msg from %d\n",recv_msg->sender);
				printfflush();
				nodes[recv_msg->sender-2].connected = TRUE;
			} else if (recv_msg->type == SUBSCRIBE) {
				printf("Received SUBSCRIBE msg from %d, to topic: %d\n",recv_msg->sender,recv_msg->topic);
				printfflush();
				//the node is connected, update its topic subscription
				if (nodes[recv_msg->sender-2].connected)
					nodes[recv_msg->sender-2].topics[recv_msg->topic] = TRUE;
					
				//debug topic list for the node
				for(i=0;i<3;i++){
					printf("node[%u].topic[%u] = %u\n", recv_msg->sender,i, nodes[recv_msg->sender-2].topics[i]);
					printfflush();
				}	
				
			} else if (recv_msg->type == PUBLISH) {
				queue_msg_t to_enqueue;
				printf("Received PUBLISH msg\tfrom %u\ttopic:%u\tpayload:%u\n",recv_msg->sender,recv_msg->topic, recv_msg->payload);
				printfflush();
				
			
				for (i=0; i<NUM_NODE; i++){

					if (nodes[i].topics[recv_msg->topic]){
						to_enqueue.dest = i+2;
						to_enqueue.payload = recv_msg;

						if ( (call MsgQueue.enqueue(to_enqueue)) == SUCCESS){
							printf("Enqueued message, with dest:%d\t and payload: topic=%d, sender=%d, payload=%d\n", to_enqueue.dest, to_enqueue.payload->topic, to_enqueue.payload->sender, to_enqueue.payload->payload);
							printfflush();
						}
						else {
							printf("Error in enqueueing message, the queue was already full");
							printfflush();
						} 
					}
				}
				
				if (call MsgQueue.empty() == FALSE )	
					send_publish();	
			}
		}
	
		return bufPtr;
	}
	
	
	
	bool actual_send (uint16_t address, message_t* packet){

		if (!locked){
			if (call AMSend.send(address, packet, sizeof(pub_sub_msg_t)) == SUCCESS)
				locked = TRUE;

			printf("Locking the radio, sending msg...\n");
			printfflush();
		}

		return locked;	  
	}
  
   	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		/* This event is triggered when a message is sent 
		*  Check if the packet is sent
		*/
		if (&packet == bufPtr)
			locked = FALSE;

		printf("Send done, unlocking the radio\n");
		printfflush();
		
 		if (call MsgQueue.empty() == FALSE)
			send_publish();	 
	}
	  
	  


	  
}



