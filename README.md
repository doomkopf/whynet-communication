# Whynet-Communication

A protocol layer on top of Whynet-Connection supporting clients to request for specific commands from a server. On the server-side CommandHandlers can be implemented to handle specific commands.

## Public components

### RequestCommandHandler

The server-side reception handling for commands through CommandHandlers. Pass it to a WhynetConnection.Server as the receptionListener.

### CommandClient

Client for sending requests to process a specific command on a server and getting a result.
