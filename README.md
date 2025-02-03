# IOT Project 2022-2023

The project required to emulate in TinyOS a lightweight publish/subscribe protocol of communication, with two actors:
   - PAN Coordinator, a self elected node that acts as the broker of the protocol of communication;
   - Motes, 8 different mote that can connect to the broker, subscribe to some topics (in our case they were only 3) and publish (one topic per mote, with random payload).

Specifically the assignement requires to design and implement in TinyOS a lightweight publish/subscribe application protocol similar to MQTT and test it with simulations on a star-shaped network topology composed of 8 client nodes connected to
a PAN coordinator. The PAN coordinator acts as an MQTT broker.

The following features need to be implemented:
   1. Connection: upon activation, each node sends a CONNECT message to the PAN coordinator. The PAN coordinator replies with a CONNACK message. If the PAN coordinator receives messages from not yet connected nodes, such messages are ignored. Be sure to handle retransmissions if msgs get lost (retransmission if CONN or CONNACK is lost).
   2. Subscribe: After connection, each node can subscribe to one among these three topics: TEMPERATURE, HUMIDITY, LUMINOSITY. In order to subscribe, a node sends a SUBSCRIBE message to the PAN coordinator, containing its node ID and the topics it wants to subscribe to (use integer topics). Assume the subscriber always use QoS=0 for subscriptions. The subscribe message is acknowledged by the PANC with a SUBACK message. (handle retransmission if SUB or SUBACK is lost)
   3. Publish: each node can publish data on at most one of the three aforementioned topics. The publication is performed through a PUBLISH message with the following fields: topic name, payload (assume that always QoS=0). When a node publishes a message on a topic, this is received by the PAN and forwarded to all nodes that have subscribed to a particular topic.
   4. You are free to test the implementation in the simulation environment you prefer (TOSSIM or Cooja), with at least 3 nodes subscribing to more than 1 topic. The payload of PUBLISH messages on all topics can be a random number.
   5. The PAN Coordinator (Broker node) should be connected to Node-RED, and periodically transmit data received on the topics to ThingsSpeak through MQTT. Thingspeak must show one chart for each topic on a public channel.

## Application
The application is divided into two parts: one about the mote and one about the PAN Coordinator. The reason of this choice is that the behaviour of the two components is deeply different (even with different requirements in term of memory usage and radio usage, i.e., in terms of energy consumption in case of real world scenarios). Still there are some common portion to be shared between this two type of components, in fact, we have a common LwPubSubMsg.h file, an header files that contains shared variables and definitions.

## Simulation
The simulation of our application was performed by Cooja where we created a star topology, with random positions per each mote, but checking that every mote was able to communicate with the broker. Details and logs can be found in the Report folder, together with a more in-detail explanation of such project and simulations results.
