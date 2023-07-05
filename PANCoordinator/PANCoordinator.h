#ifndef PANCOORDINATOR_H
#define PANCOORDINATOR_H

#include "../LwPubSubMsgs.h"

//Chosen parameter for size of pub_message queue
#define MSG_QUEUE_SIZE 32

//Struct to handle node information on the broker
typedef struct node_info{
	bool connected;	//True if node is connected, false otherwise
	bool topics[3];	//Each position i correspond to topic i, with value true if node is subscribed, false otherwise
} node_info;

//Struct to save values of the pub message to be forwarded
typedef struct queue_msg{
	uint16_t dest;			//ID of the receiver of the enqueued message
	uint8_t type;			//type of the message (always 2)
	uint8_t sender;		//sender of the former publication message
	uint8_t topic;			//topic of the former publication message
	uint16_t payload;		//payload of the former publication message
} queue_msg_t;

#endif
