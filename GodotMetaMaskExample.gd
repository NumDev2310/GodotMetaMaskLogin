extends Control

const _authReceiver = preload("res://Auth.tscn")
const _authVerifier = preload("res://NethereumCS.cs")
const authTokenExpiryMetaMask = 30

@onready var _verifierInstance := _authVerifier.new()
@onready var _loginButton = get_node("Button")
@onready var _logoutButton = get_node("LogoutButton")

var _ip = "127.0.0.1"
var _port = 25001
var _mpNode
var myPeerID
var _i_am_server : bool = true
var rng = RandomNumberGenerator.new()
var ConnectedChatClients = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var my_id
	if OS.is_debug_build():
		var dir = DirAccess.open("user://tmp/")
		if dir == null:
			var newdir = DirAccess.open("user://")
			newdir.make_dir("tmp")
			dir = DirAccess.open("user://tmp/")
		for file in dir.get_files():
			dir.remove(file)
		await get_tree().create_timer(3).timeout
		
		my_id = rng.randi()
		var file = FileAccess.open("user://tmp/" + str(my_id), FileAccess.WRITE)
		file.store_string("1")
		
		await get_tree().create_timer(2).timeout
	
		dir = DirAccess.open("user://tmp/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				print(file_name)
				if my_id < int(file_name):
					_i_am_server = false
				file_name = dir.get_next()
	print("Has this debug instance been designated a Server instance?", _i_am_server)

	DisplayServer.window_set_size(Vector2(800,500),0)
	DisplayServer.window_set_current_screen(2,0)
	if _i_am_server:
		DisplayServer.window_set_position(Vector2(100,100),0)
	else:
		DisplayServer.window_set_position(Vector2(700,200),0)
	DisplayServer.window_set_current_screen(2,0)
	if _i_am_server:
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), self.get_path())
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_server(_port, 4000, 0, 0, 0)
		if err != OK:
			print("failed to create peer")
			return
		_mpNode = get_tree().get_multiplayer(NodePath("."))
		_mpNode.peer_connected.connect(_on_peer_connected)
		_mpNode.peer_disconnected.connect(_on_peer_disconnected)
		_mpNode.multiplayer_peer = peer
		myPeerID = _mpNode.get_unique_id()
		ConnectedChatClients[1] = ChatClient.new(1, true, "ServerPseudonym")
	else:
		get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), self.get_path())
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_client(_ip, _port, 0, 0, 0, 0)
		if err != OK:
			print("failed to create peer")
			return
		_mpNode = get_tree().get_multiplayer(NodePath("."))
		_mpNode.multiplayer_peer = peer
		myPeerID = _mpNode.get_unique_id()

func _on_peer_connected(new_peer_id: int):
	if _i_am_server:
		ConnectedChatClients[new_peer_id] = ChatClient.new(new_peer_id, true, "SomePseudonym")
		print("Peer connected:" + str(new_peer_id))
	
func _on_peer_disconnected(peer_id: int):
	if _i_am_server:
		ConnectedChatClients.erase([peer_id])
		print("Peer disconnected:" + str(peer_id))

func _on_button_pressed():
	_mpNode.rpc(1,self,&"requestAuthToken", [_mpNode.get_unique_id()])

func setupWebSocketFinale():
	var auth = _authReceiver.instantiate()
	add_child(auth)
	
func submitFinalAuthProof(reconstitutedMsg : String, signature : String, pubaddress : String, message : String):
	_mpNode.rpc(1,self,&"finalAuthProofSubmission", [_mpNode.get_unique_id(), reconstitutedMsg, signature, pubaddress, message])
	
@rpc("any_peer", "call_local", "reliable", 0)
func requestAuthToken(peerid : int):
	if _i_am_server and _mpNode.get_remote_sender_id() == peerid:
		var authtoken = rng.randi()
		var timestamp = Time.get_unix_time_from_system()
		ConnectedChatClients[peerid].authToken = authtoken
		ConnectedChatClients[peerid].authTokenTimestamp = timestamp
		_mpNode.rpc(peerid,self,&"receiveAuthToken", [peerid, authtoken, timestamp])
		
@rpc("authority", "call_local", "reliable", 0)
func receiveAuthToken(peerid : int, authtoken : int, timestamp: float):
		OS.shell_open("https://auth.numdev.live/?authtoken=" + str(authtoken) + "&timestamp=" + str(timestamp) + "&peer=" + str(peerid))
		setupWebSocketFinale()
		
@rpc("any_peer", "call_local", "reliable", 0)
func finalAuthProofSubmission(peerid : int, reconstitutedMsg : String, signature : String, pubaddress : String, message : String):
	if _i_am_server and _mpNode.get_remote_sender_id() == peerid:
		var splitMessage = message.split("!")
		if splitMessage.size() == 12:
			if "Original Message: " == splitMessage[0] and "I am peer " == splitMessage[1] and " requesting to login to AuthDev with authorization " == splitMessage[3] and " at timestamp " == splitMessage[5] and "." == splitMessage[7] and " Signature: " == splitMessage[8] and " Public Address: " == splitMessage[10]:
				if int(splitMessage[2]) == peerid:
					if Time.get_unix_time_from_system() - float(splitMessage[6]) < authTokenExpiryMetaMask:
						if splitMessage[6] == str(ConnectedChatClients[peerid].authTokenTimestamp) and splitMessage[4] == str(ConnectedChatClients[peerid].authToken):
							var reconstitutedMsg2 = splitMessage[1] + splitMessage[2] + splitMessage[3] + splitMessage[4] + splitMessage[5] + splitMessage[6] + splitMessage[7]
							if reconstitutedMsg2 == reconstitutedMsg:
								var recoveredAddress = _verifierInstance.EcRecover(reconstitutedMsg2, splitMessage[9])
								if recoveredAddress.to_lower() == splitMessage[11].to_lower() and recoveredAddress.to_lower() == pubaddress.to_lower():
									ConnectedChatClients[peerid].isAuthenticated = true
									ConnectedChatClients[peerid].publicID = splitMessage[11]
									_mpNode.rpc(peerid,self,&"confirmAuth", [peerid, splitMessage[11]])
									
@rpc("authority", "call_local", "reliable", 0)
func confirmAuth(peerid : int, publicID : String):
	_logoutButton.visible = true
	_loginButton.visible = false
	get_node("Label").text = "Current Status: Logged in as " + publicID
