#include "project.h"

configuration projectAppC {}

implementation {

  components MainC, projectC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC;
  components new TimerMilliC() as NodeTimerC;
  components new TimerMilliC() as PanCoordinatorTimerC;
  components RandomC;


  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements->ActiveMessageC;

  //Timer interface
  App.NodeTimer -> NodeTimerC;
  App.PanCoordinatorTimer -> PanCoordinatorTimerC;

  //Fake sensor
  RandomC <- MainC.SoftwareInit;
  App.FakeSensor -> RandomC;


}
