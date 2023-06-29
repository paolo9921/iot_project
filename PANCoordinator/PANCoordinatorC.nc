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
		//interface Queue<uint16_t> as DestQueue;
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
				for(j=0; j<3; j++)
					nodes[i].topics[j] = FALSE;
			}
		printf("Nodes connection and topics initialized\n");
		printfflush();
		return;
		}
		else {
		  call AMControl.start();
		}
	  }

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}
	
	
	void send_publish(){
		queue_msg_t dequeued = (queue_msg_t) call MsgQueue.dequeue();
		//uint16_t dest = (uint16_t) call DestQueue.dequeue();
		pub_sub_msg_t* to_send = (pub_sub_msg_t *) call Packet.getPayload(&packet, sizeof(pub_sub_msg_t));
		
		*to_send = *dequeued.payload;
		actual_send(dequeued.dest, &packet);
	}
	

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
			
		if (len == sizeof(pub_sub_msg_t)) {
			pub_sub_msg_t* recv_msg = (pub_sub_msg_t*)payload;
		
			// when receive a CON msg, send CONNACK and mark this node as connected
			if (recv_msg->type == CONNECT){
					
				printf("Received CONNECT msg from %d\n",recv_msg->sender);
				printfflush();
				nodes[recv_msg->sender-1].connected = TRUE;
			} else if (recv_msg->type == SUBSCRIBE) {
				printf("Received SUBSCRIBE msg from %d, to topic: %d\n",recv_msg->sender,recv_msg->topic);
				printfflush();
				//the node is connected, update its topic subscription
				if (nodes[recv_msg->sender-1].connected)
					nodes[recv_msg->sender-1].topics[recv_msg->topic] = TRUE;	
			} else if (recv_msg->type == PUBLISH) {
				bool s;
				queue_msg_t to_enqueue;
				printf("Received PUBLISH msg\tfrom %u\ttopic:%u\tpayload:%u\n",recv_msg->sender,recv_msg->topic, recv_msg->payload);
				printfflush();
			
				for (i=0; i<NUM_NODE; i++){
					if (nodes[i].topics[recv_msg->topic]){
						//r = (call DestQueue.enqueue(i+1)) == SUCCESS;
						to_enqueue.dest = i+1;
						to_enqueue.payload = recv_msg;
						s = (call MsgQueue.enqueue(to_enqueue)) == SUCCESS;
						printf("Enqueued message, with dest:%d\t and payload: %d, %d, %d\n", to_enqueue.dest, to_enqueue.payload->topic, to_enqueue.payload->sender, to_enqueue.payload->payload);
						printf("%u, %u\n", s, call MsgQueue.size());
						printfflush();
					}
				}	
				send_publish();	
			}
		}
	
		return bufPtr;
	}
	
	
	
	bool actual_send (uint16_t address, message_t* packet){

		if (!locked){
			if (call AMSend.send(address, packet, sizeof(pub_sub_msg_t)) == SUCCESS)
				locked = TRUE;

			printf("Sending msg to: %d, on topic:\n", address);
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



