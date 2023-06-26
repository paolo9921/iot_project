#ifndef PANCOORDINATOR_H
#define PANCOORDINATOR_H

#include "LwPubSubMsgs.h"

typedef nx_struct node_info{
	uint8_t connected;
	uint8_t topics[3];
}node_info;

#endif
