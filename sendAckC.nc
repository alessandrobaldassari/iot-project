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
		interface Timer<TMilli> as MilliTimer;
	}
} 
implementation{
	// common variables
    uint8_t msg_counter=0;
	uint8_t rec_id;
    message_t packet;
    
    // pan coordinator variables
    uint8_t sub[MAX_NODES][ID_AND_TOPICS];
    uint8_t qos[MAX_NODES][ID_AND_TOPICS];
    
    // node variables
	uint8_t node_status;
    
    // tasks
	task void sendConnectionRequest();
    task void sendSubscriptionRequest();
	
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
        mess->temp = 1;
        mess->temp_qos = 0;
        mess->hum = 0;
        mess->hum_qos = 0;
        mess->lum = 1;
        mess->lum_qos = 1;
	
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
    
	// MilliTimer interface  
	event void MilliTimer.fired(){
        if(TOS_NODE_ID != PAN_COORD){
            if(node_status == DISCONNECTED){
                post sendConnectionRequest();
            }
            else if(node_status = CONNECTED){
                post sendSubscriptionRequest();
            }
            else if(node_status = SUBSCRIBED){

            }
        }						
	}
	
	// SplitControl interface
	event void SplitControl.startDone(error_t err){
		if(err == SUCCESS){	
			dbg("radio","Radio on!\n");
			if (TOS_NODE_ID != PAN_COORD){
				dbg("role","I'm node %hhu: start sending periodical CONNECT request\n", TOS_NODE_ID);
				node_status = DISCONNECTED;
				dbg("role","Node status: %hhu (DISCONNECTED)\n", node_status);
				call MilliTimer.startPeriodic(800);
			}
			else if (TOS_NODE_ID == PAN_COORD){
				dbg("role","I'm node %hhu: PAN COORDINATOR\n", TOS_NODE_ID);
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
            if(TOS_NODE_ID != PAN_COORD){
                if (call PacketAcknowledgements.wasAcked(buf)){			
                    dbg_clear("radio_ack", "and ack received\n");
					if(node_status == DISCONNECTED){
						node_status = CONNECTED;
						dbg("radio_ack","Node status: %hhu (CONNECTED)\n", node_status);
					}
                    else if (node_status = CONNECTED){
                        node_status = SUBSCRIBED;
						dbg("radio_ack","Node status: %hhu (SUBSCRIBED)\n", node_status);
                        call MilliTimer.stop();
                    }
                    else if (node_status = SUBSCRIBED){
                        node_status = PUBLISHING;
						dbg("radio_ack","Node status: %hhu (PUBLISHING)\n", node_status);
                    }						
                }
                else{
                    dbg_clear("radio_ack", "but ack was not received");
                    if(node_status == DISCONNECTED){
                        post sendConnectionRequest();
					}
                    else if (node_status = CONNECTED){
                        post sendSubscriptionRequest();
                    }
                    else if (node_status = SUBSCRIBED){

                    }			
                }
            }
            else if(TOS_NODE_ID == PAN_COORD){
                if (call PacketAcknowledgements.wasAcked(buf)){			
                    dbg_clear("radio_ack", "and ack received\n");
                }
                else{
                    dbg_clear("radio_ack", "but ack was not received");
                }
            }
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		}
	}
	
	// Receive interface 
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len){
        // cast to the longest message type
        sub_msg_t* mess=(sub_msg_t*)payload;
        rec_id = mess->msg_id;
        
        dbg("radio_rec","Message received at time %s \n", sim_time_string());
        dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength(buf));
        dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source(buf));
        dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination(buf));
        dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type(buf));
        dbg_clear("radio_pack","\t\t Payload \n");
        dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
        dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
		
		if (TOS_NODE_ID == PAN_COORD){
			switch(mess->msg_type){
				case(CONNECT):
					break;
				case(SUBSCRIBE):
                    dbg_clear("radio_pack", "\t\t dev_id: %hhu \n", mess->dev_id);
                    dbg_clear("radio_pack", "\t\t temp: %hhu \n ", mess->temp);
                    dbg_clear("radio_pack", "\t\t temp_qos: %hhu \n", mess->temp_qos);
                    dbg_clear("radio_pack", "\t\t hum: %hhu \n ", mess->hum);
                    dbg_clear("radio_pack", "\t\t hum_qos: %hhu \n", mess->hum_qos);
                    dbg_clear("radio_pack", "\t\t lum: %hhu \n ", mess->lum);
                    dbg_clear("radio_pack", "\t\t lum_qos: %hhu \n\n", mess->lum_qos);
                    
                    sub[mess->dev_id - DELTA][TEMPERATURE] = mess->temp;
                    sub[mess->dev_id - DELTA][HUMIDITY] = mess->hum;
                    sub[mess->dev_id - DELTA][LUMINOSITY] = mess->lum;
                    qos[mess->dev_id - DELTA][TEMPERATURE] = mess->temp_qos;
                    qos[mess->dev_id - DELTA][HUMIDITY] = mess->hum_qos;
                    qos[mess->dev_id - DELTA][LUMINOSITY] = mess->lum_qos;
                    
                    dbg("radio_rec", ">>> SUBSCRIPTION by node %hhu\n", mess->dev_id);
                    dbg("radio_rec", "TOPIC Temp: %hhu - Lum: %hhu - Hum: %hhu\n", sub[mess->dev_id - DELTA][TEMPERATURE] , sub[mess->dev_id - DELTA][HUMIDITY], sub[mess->dev_id - DELTA][LUMINOSITY]);
                    dbg("radio_rec", "QOS Temp: %hhu - Lum: %hhu - Hum: %hhu\n", qos[mess->dev_id - DELTA][TEMPERATURE] , qos[mess->dev_id - DELTA][HUMIDITY], qos[mess->dev_id - DELTA][LUMINOSITY]);
                    
					break;
				case(PUBLISH):
					break;
				default:
					dbg("radio_rec","Unknown message type: %hhu \n", mess->msg_type);
			}
            dbg_clear("radio_rec", "\n ");
            dbg_clear("radio_pack","\n");
		}
		return buf;
	}
}        
	
	
	
	
	
	
	
	
	
	
	



