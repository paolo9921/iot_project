#ifndef PANCOORDINATOR_H
#define PANCOORDINATOR_H

#include "../LwPubSubMsgs.h"

#define MSG_QUEUE_SIZE 32

typedef struct node_info{
	bool connected;
	bool topics[3];
} node_info;

typedef struct queue_msg{
	uint16_t dest;
	pub_sub_msg_t * payload;
} queue_msg_t;

#endif
