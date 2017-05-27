#ifndef SENDACK_H
#define SENDACK_H

// pan coordinator id
#define PAN_COORD 1

// maximum number of nodes connected to the pan coordinator
#define MAX_NODES 8

// message type
#define CONNECTION 1
#define SUBSCRIBE 2
#define PUBLISH 3

// node status
#define DISCONNECTED 1
#define CONNECTED 2
#define SUBSCRIBED 3



typedef nx_struct my_msg{
	nx_uint8_t msg_type;
	nx_uint16_t msg_id;
} conn_msg_t;

enum{ AM_MY_MSG = 6 };

#endif
