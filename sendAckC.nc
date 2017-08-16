#include "sendAck.h"
#include "Timer.h"

module sendAckC{
	uses{
		interface Boot;
		interface AMPacket;
		interface Packet;
		interface PacketAcknowledgements;
		interface AMSend;
		interface SplitControl;
		interface Receive;
        interface Timer<TMilli> as NodeTimer;
        interface Timer<TMilli> as PanCoordinatorTimer;
        interface Random as FakeSensor;
	}
}
implementation{
	// common variables
    uint8_t msg_counter=0;
	uint8_t rec_id;
    message_t packet;
    uint8_t iter = 0;

    // pan coordinator variables
    uint8_t sub_counter = 0;
    uint8_t sub_table[MAX_NODES][ID_TOPICS_QOS];
    uint8_t i = 0,j;
    uint8_t locked = 0;
    uint8_t topic, source;
    uint16_t value;

    // node variables
	uint8_t node_status;

    // tasks
	task void sendConnectionRequest();
    task void sendSubscriptionRequest();
    task void publishData();
	task void forwardData();

	// Task send connection request
	task void sendConnectionRequest(){
		conn_msg_t* mess=(conn_msg_t*)(call Packet.getPayload(&packet,sizeof(conn_msg_t)));
		mess->msg_type = CONNECT;
		mess->msg_id = msg_counter++;

		dbg("radio_send", "Try to send a CONNECT request to PAN COORDINATOR at time %s \n", sim_time_string());

		call PacketAcknowledgements.requestAck(&packet);

		if(call AMSend.send(PAN_COORD,&packet,sizeof(conn_msg_t)) == SUCCESS){
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
			dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source(&packet));
			dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination(&packet));
			dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type(&packet));
			dbg_clear("radio_pack","\t\t Payload \n");
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
			dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
			dbg_clear("radio_send", "\n ");
			dbg_clear("radio_pack", "\n");
		}
	}

    // Task send subscription request
	task void sendSubscriptionRequest(){
		sub_msg_t* mess=(sub_msg_t*)(call Packet.getPayload(&packet,sizeof(sub_msg_t)));
		mess->msg_type = SUBSCRIBE;
		mess->msg_id = msg_counter++;
        mess->dev_id = TOS_NODE_ID;
        //Subscription initialization based on node ID
        if(TOS_NODE_ID == 3 || TOS_NODE_ID == 6|| TOS_NODE_ID == 9){
            mess->temp = 1;
            mess->temp_qos = 1;
            mess->hum = 0;
            mess->hum_qos = 0;
            mess->lum = 1;
            mess->lum_qos = 0;
        }
        else{
            mess->temp = 0;
            mess->temp_qos = 0;
            mess->hum = 1;
            mess->hum_qos = 1;
            mess->lum = 0;
            mess->lum_qos = 0;
        }

		dbg("radio_send", "Try to send a SUBSCRIBE request to PAN COORDINATOR at time %s \n", sim_time_string());

		call PacketAcknowledgements.requestAck(&packet);

		if(call AMSend.send(PAN_COORD,&packet,sizeof(sub_msg_t)) == SUCCESS){
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
            dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source(&packet));
            dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination(&packet));
            dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type(&packet));
            dbg_clear("radio_pack","\t\t Payload \n");
            dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
            dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
            dbg_clear("radio_pack", "\t\t dev_id: %hhu \n", mess->dev_id);
            dbg_clear("radio_pack", "\t\t temp: %hhu \n ", mess->temp);
            dbg_clear("radio_pack", "\t\t temp_qos: %hhu \n", mess->temp_qos);
            dbg_clear("radio_pack", "\t\t hum: %hhu \n ", mess->hum);
            dbg_clear("radio_pack", "\t\t hum_qos: %hhu \n", mess->hum_qos);
            dbg_clear("radio_pack", "\t\t lum: %hhu \n ", mess->lum);
            dbg_clear("radio_pack", "\t\t lum_qos: %hhu \n", mess->lum_qos);
            dbg_clear("radio_send", "\n ");
            dbg_clear("radio_pack", "\n");
		}
	}

    // Task publish data
	task void publishData(){
		pub_msg_t* mess=(pub_msg_t*)(call Packet.getPayload(&packet,sizeof(pub_msg_t)));
		mess->msg_type = PUBLISH;
		mess->msg_id = msg_counter++;
        mess->topic = call FakeSensor.rand16() % 3 + 1;
        mess->value = call FakeSensor.rand16();
        //Publish QoS initialization based on node ID
        if(TOS_NODE_ID == 2 || TOS_NODE_ID == 4 || TOS_NODE_ID == 9){
            mess->qos = 0;
        }
        else{
            mess->qos = 1;
        }
        dbg("radio_send", "Try to send a PUBLISH message to PAN COORDINATOR at time %s \n", sim_time_string());

		if(mess->qos == QOS){
            call PacketAcknowledgements.requestAck(&packet);
        }
        else{
            call PacketAcknowledgements.noAck(&packet);
        }

		if(call AMSend.send(PAN_COORD,&packet,sizeof(pub_msg_t)) == SUCCESS){
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
            dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source(&packet));
            dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination(&packet));
            dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type(&packet));
            dbg_clear("radio_pack","\t\t Payload \n");
            dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
            dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
            dbg_clear("radio_pack", "\t\t topic: %hhu \n", mess->topic);
            dbg_clear("radio_pack", "\t\t value: %hhu \n ", mess->value);
            dbg_clear("radio_pack", "\t\t qos: %hhu \n ", mess->qos);
            dbg_clear("radio_send", "\n ");
            dbg_clear("radio_pack", "\n");
		}
	}

    // Task forward data
	task void forwardData(){
		pub_msg_t* mess=(pub_msg_t*)(call Packet.getPayload(&packet,sizeof(pub_msg_t)));
		mess->msg_type = PUBLISH;
		mess->msg_id = msg_counter++;
        mess->topic = topic;
        mess->value = value;
        

        if(sub_table[i][ID] != source && sub_table[i][mess->topic] == 1){
            mess->qos = sub_table[i][mess->topic + OFFSET];
            dbg("radio_rec","Forward to node %hhu, source %hhu. QoS: %hhu\n", sub_table[i][ID], source, sub_table[i][mess->topic + OFFSET]);
            if(mess->qos){
                call PacketAcknowledgements.requestAck(&packet);
            }
            else{
            call PacketAcknowledgements.noAck(&packet);
            }
            if(call AMSend.send(sub_table[i][ID],&packet,sizeof(pub_msg_t)) == SUCCESS){
                dbg("radio_send", "Packet passed to lower layer successfully!\n");
                dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
                dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source(&packet));
                dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination(&packet));
                dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type(&packet));
                dbg_clear("radio_pack","\t\t Payload \n");
                dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
                dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
                dbg_clear("radio_pack", "\t\t topic: %hhu \n", mess->topic);
                dbg_clear("radio_pack", "\t\t value: %hhu \n ", mess->value);
                dbg_clear("radio_pack", "\t\t qos: %hhu \n ", mess->qos);
                dbg_clear("radio_send", "\n ");
                dbg_clear("radio_pack", "\n");
            }
        }
        //dbg("radio_send","sub_value: %hhu i: %hhu source: %hhu topic %hhu\n", sub_counter, i, source, topic);
        i++;
        if(i == sub_counter){
            i = 0;
            locked = 0;
            call PanCoordinatorTimer.stop();
        }
	}

	// NodeTimer interface
	event void NodeTimer.fired(){
        switch(node_status){
            case(DISCONNECTED):
                post sendConnectionRequest();
                break;

            case(CONNECTED):
                post sendSubscriptionRequest();
                break;

            case(SUBSCRIBED):
                post publishData();
                break;

            default:
                break;

        }
    }

    // PanCoordinatorTimer interface
	event void PanCoordinatorTimer.fired(){
        post forwardData();

    }

	// SplitControl interface
	event void SplitControl.startDone(error_t err){
		if(err == SUCCESS){
			dbg("radio","Radio on!\n");
			if (TOS_NODE_ID == PAN_COORD){
                dbg("role","I'm node %hhu: PAN COORDINATOR\n", TOS_NODE_ID);
			}
			else if (TOS_NODE_ID != PAN_COORD){
                node_status = DISCONNECTED;
                call NodeTimer.startPeriodic(NODE_TIMER);

                dbg("role","I'm node %hhu: start sending periodical CONNECT request\n", TOS_NODE_ID);
				dbg("role","Node status: %hhu (DISCONNECTED)\n", node_status);
			}
		}
		else{
			call SplitControl.start();
		}
	}

	event void SplitControl.stopDone(error_t err){}

	// Boot interface
	event void Boot.booted(){
		dbg("boot","Application booted.\n");
		call SplitControl.start();
	}

	// AMSend interface
	event void AMSend.sendDone(message_t* buf,error_t err){
		if(&packet == buf && err == SUCCESS){
			dbg("radio_send", "Packet sent...");

            if(TOS_NODE_ID == PAN_COORD){
                if (call PacketAcknowledgements.wasAcked(buf)){
                    dbg_clear("radio_ack", "and ack received\n");
                }
                else{
                    dbg_clear("radio_ack", "but ack was not received");
                    i--;
                    post forwardData();
                }
            }
            else if(TOS_NODE_ID != PAN_COORD){
                if (call PacketAcknowledgements.wasAcked(buf)){
                    dbg_clear("radio_ack", "and ack received\n");
                    switch(node_status){
                        case(DISCONNECTED):
                            node_status = CONNECTED;

                            dbg("radio_ack","Node status: %hhu (CONNECTED)\n", node_status);
                            break;

                        case(CONNECTED):
                            node_status = SUBSCRIBED;

                            dbg("radio_ack","Node status: %hhu (SUBSCRIBED)\n", node_status);
                            break;

                        default:
                            break;
                    }
                }
                else{
                        dbg_clear("radio_ack", "but ack was not received");
                }

                }
            }

        dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }


	// Receive interface
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len){
        // cast to the longest message type
        conn_msg_t* conn_mess=(conn_msg_t*)payload;
        sub_msg_t* sub_mess=(sub_msg_t*)payload;
        pub_msg_t* pub_mess=(pub_msg_t*)payload;

        dbg("radio_rec","Message received at time %s %hhu \n", sim_time_string(), len);
        dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength(buf));
        dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source(buf));
        dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination(buf));
        dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type(buf));
        dbg_clear("radio_pack","\t\t Payload \n");

		if (TOS_NODE_ID == PAN_COORD){
			switch(sub_mess->msg_type){
				case(CONNECT):
                    dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", conn_mess->msg_type);
                    dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", conn_mess->msg_id);
					break;

				case(SUBSCRIBE):

                    dbg_clear("radio_pack", "\t\t dev_id: %hhu \n", sub_mess->dev_id);
                    dbg_clear("radio_pack", "\t\t temp: %hhu \n ", sub_mess->temp);
                    dbg_clear("radio_pack", "\t\t hum: %hhu \n ", sub_mess->hum);
                    dbg_clear("radio_pack", "\t\t lum: %hhu \n ", sub_mess->lum);
                    dbg_clear("radio_pack", "\t\t temp_qos: %hhu \n", sub_mess->temp_qos);
                    dbg_clear("radio_pack", "\t\t hum_qos: %hhu \n", sub_mess->hum_qos);
                    dbg_clear("radio_pack", "\t\t lum_qos: %hhu \n\n", sub_mess->lum_qos);

                    // recording subscription data
                    sub_table[sub_counter][ID] = sub_mess->dev_id;
                    sub_table[sub_counter][TEMPERATURE] = sub_mess->temp;
                    sub_table[sub_counter][HUMIDITY] = sub_mess->hum;
                    sub_table[sub_counter][LUMINOSITY] = sub_mess->lum;
                    sub_table[sub_counter][TEMPERATURE + OFFSET] = sub_mess->temp_qos;
                    sub_table[sub_counter][HUMIDITY + OFFSET] = sub_mess->hum_qos;
                    sub_table[sub_counter][LUMINOSITY + OFFSET] = sub_mess->lum_qos;

                    dbg("radio_rec", " >>> SUBSCRIPTION by node %hhu\n", sub_mess->dev_id);
                    for(iter = 0; iter <= sub_counter; iter++){
                        dbg("radio_rec", "\tID %hhu \n", sub_table[iter][ID]);
                        dbg("radio_rec", "\tTOPIC Temp: %hhu - Hum: %hhu - Lum: %hhu\n", sub_table[iter][TEMPERATURE] , sub_table[iter][HUMIDITY], sub_table[iter][LUMINOSITY]);
                        dbg("radio_rec", "\tQOS   Temp: %hhu - Hum: %hhu - Lum: %hhu\n", sub_table[iter][TEMPERATURE + OFFSET] , sub_table[iter][HUMIDITY + OFFSET], sub_table[iter][LUMINOSITY + OFFSET]);
                    
                    }
                    sub_counter++;
					break;

				case(PUBLISH):
                    dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", pub_mess->msg_type);
                    dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", pub_mess->msg_id);
                    dbg_clear("radio_pack", "\t\t topic: %hhu \n", pub_mess->topic);
                    dbg_clear("radio_pack", "\t\t value: %hhu \n ", pub_mess->value);
                    dbg_clear("radio_pack", "\t\t QoS: %hhu \n ", pub_mess->qos);

                    if(locked == 0){
                        value = pub_mess->value;
                        topic = pub_mess->topic;
                        source = call AMPacket.source(buf);
                        locked = 1;
                        call PanCoordinatorTimer.startPeriodic(PAN_TIMER);
                    }



					break;

				default:
					dbg("radio_rec","Unknown message type: %hhu \n", conn_mess->msg_type);
			}
            if(TOS_NODE_ID != PAN_COORD){
                dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", pub_mess->msg_type);
                    dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", pub_mess->msg_id);
                    dbg_clear("radio_pack", "\t\t topic: %hhu \n", pub_mess->topic);
                    dbg_clear("radio_pack", "\t\t value: %hhu \n ", pub_mess->value);
                    dbg_clear("radio_pack", "\t\t QoS: %hhu \n ", pub_mess->qos);

            }
            dbg_clear("radio_rec", "\n ");
            dbg_clear("radio_pack","\n");
		}
		return buf;
	}
}
