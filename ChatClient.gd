extends Node

class_name ChatClient

var peerid : int
var isAuthenticated : bool = false
var publicID : String = ""
var isConnected : bool = false
var userName : String = ""
var authToken : int = 0
var authTokenTimestamp : float = 0.0

func _init(peer : int, connected : bool, uname : String):
	peerid = peer
	isConnected = connected
	userName = uname	
