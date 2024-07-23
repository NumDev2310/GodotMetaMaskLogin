extends Control

const whiteListedIPsLocal = [	"0:0:0:0:0:0:0:1",
								"0:0:0:0:0:0:1",	
								"0:0:0:0:0:1",
								"0:0:0:0:1",
								"0:0:0:1",
								"127:0:0:1",
								"localhost" ]
const authTokenExpiryMetaMask = 30

var ethereum = preload("res://NethereumCS.cs")
@onready var ethInstance := ethereum.new()

func _ready():
	start_server()

func start_server():
	$WebSocketServer.listen(12081)

func _on_web_socket_server_message_received(peer_id, message):
	var ip = get_node("WebSocketServer").peers[peer_id].get_connected_host()
	if whiteListedIPsLocal.has(ip):
		var splitMessage = message.split("!")
		if splitMessage.size() == 12:
			if "Original Message: " == splitMessage[0] and "I am peer " == splitMessage[1] and " requesting to login to AuthDev with authorization " == splitMessage[3] and " at timestamp " == splitMessage[5] and "." == splitMessage[7] and " Signature: " == splitMessage[8] and " Public Address: " == splitMessage[10]:
				if Time.get_unix_time_from_system() - float(splitMessage[6]) < authTokenExpiryMetaMask:
					var reconstitutedMsg = splitMessage[1] + splitMessage[2] + splitMessage[3] + splitMessage[4] + splitMessage[5] + splitMessage[6] + splitMessage[7]
					var recoveredAddress = ethInstance.EcRecover(reconstitutedMsg, splitMessage[9])
					get_parent().submitFinalAuthProof(reconstitutedMsg, splitMessage[9], splitMessage[11], message)
