#ifndef LWPUBSUBMSGS_H
#define LWPUBSUBMSGS_H

#include "message.h"


typedef nx_struct pub_sub_msg{
	nx_uint8_t type;
	nx_uint8_t sender;
	nx_uint8_t topic;
	nx_uint16_t payload;
} pub_sub_msg_t;

enum{
	AM_PUBSUB_MSG = 6,
	};
