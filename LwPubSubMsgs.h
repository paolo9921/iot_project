#ifndef LWPUBSUBMSGS_H
#define LWPUBSUBMSGS_H

#include "message.h"

//Assumption made that after 5 seconds without receiving an ack the message was lost
#define TIME_TO_LOSS 5000
#define PUB_SUB_MSG_SIZE sizeof(pub_sub_msg_t)

//Message struct for pub/sub messages
typedef nx_struct pub_sub_msg{
	nx_uint8_t type;			//type of message
	nx_uint8_t sender;		//ID of the sender node
	nx_uint8_t topic;			//topic of the pub or sub message, ignored for connection
	nx_uint16_t payload;		//payload of the pub message, ignored otherwise
} pub_sub_msg_t;

enum{ AM_PUBSUB_MSG = 6 };

//Useful enumeration for type of messages
enum msg_type {CONNECT = 0, SUBSCRIBE, PUBLISH};

//Useful enumeration for topic of messages
enum topics {TEMPERATURE = 0, HUMIDITY, LUMINOSITY};

#endif
