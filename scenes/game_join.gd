extends TextureRect

# SQLite module
const SQLite = preload("res://lib/gdsqlite.gdns")

signal data_updated(lobby_ID)

onready var lobbies_grid_node = get_node("VBoxContainer/VBoxLobbies/HBoxLobbies/ScrollContainer/LobbiesGrid")
onready var player_node = get_node("VBoxContainer/VBoxLobbies/LobbiesHeader/Player")
onready var categories_node = get_node("VBoxContainer/VBoxLobbies/LobbiesHeader/Categories")
onready var connect_button_node = get_node("VBoxContainer/VBoxLobbies/LobbiesHeader/Connect")
onready var separator_node = get_node("VBoxContainer/VBoxLobbies/LobbiesHeader/Separator")
onready var wait_message_node = get_node("VBoxContainer/VBoxLobbies/MessageWait")
onready var back_node = get_node("VBoxContainer/HBoxActions/Back")

var friends_only = false
var db = null
var all_cats_size

func _ready():
	game_params.init_styles(self)
	if godotsteam.connect_steam_signal("lobby_data_update", self, "_on_lobby_data_update") != OK:
		print("Error connecting lobby_data_update")
	if godotsteam.connect("lobby_list_fetched", self, "update_list") == OK:
		godotsteam.request_lobby_list()
	else:
		print("Error connecting lobby_list_fetched")
	connect_button_node.visible = false
	
	# Create gdsqlite instance
	db = SQLite.new()
	# Open database
	if (!db.open("res://everything.db")):
		print("Cannot open database.")
	
	all_cats_size = game_params.get_all_cats(db).size()
	
	back_node.grab_focus()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		close()
		get_tree().quit()

func _on_lobby_data_update(success, steamIDLobby, steamIDMember):
	if success:
		emit_signal("data_updated", steamIDLobby)

func update_list(lobby_list):
	for child in lobbies_grid_node.get_children():
		child.queue_free()
	
	if lobby_list.empty():
		wait_message_node.text = tr("GAME_JOIN_NO_GAMES_MESSAGE")
		player_node.visible = false
		categories_node.visible = false
		return
	else:
		wait_message_node.text = ""
		
	player_node.visible = true
	categories_node.visible = true
	for lobby_item in lobby_list:
		var lobby_ID = lobby_item["steamIDLobby"]
		var child_player = player_node.duplicate(DUPLICATE_SCRIPTS)
		child_player.text = ""
		if self.connect("data_updated", child_player, "_on_data_updated", [lobby_ID]) != OK:
			print("Cannot connect data_updated to child_player")
		lobbies_grid_node.add_child(child_player)
		var child_categories = categories_node.duplicate(DUPLICATE_SCRIPTS)
		child_categories.text = ""
		if self.connect("data_updated", child_categories, "_on_data_updated", [db, all_cats_size, lobby_ID]) != OK:
			print("Cannot connect data_updated to child_player")
		lobbies_grid_node.add_child(child_categories)
		var child_connect_button = connect_button_node.duplicate(DUPLICATE_SCRIPTS)
		if self.connect("data_updated", child_connect_button, "_on_data_updated", [self, lobby_ID]) != OK:
			print("Cannot connect data_updated to child_player")
		lobbies_grid_node.add_child(child_connect_button)
		var child_separator = separator_node.duplicate(DUPLICATE_SCRIPTS)
		child_separator.text = ""
		lobbies_grid_node.add_child(child_separator)
		godotsteam.request_lobby_data(lobby_ID)

func _on_Back_pressed():
	close()
	return get_tree().change_scene("res://main.tscn")

func _on_CreateOwnGame_pressed():
	close()
	return get_tree().change_scene("res://scenes/game_params_screen.tscn")

func _on_lobby_connect_pressed(lobby_ID):
	close()
	godotsteam.connect_to_lobby(lobby_ID)

func _on_ButtonFriendsOnly_toggled(button_pressed):
	friends_only = button_pressed
	if friends_only:
		godotsteam.request_friends_lobby_list()
	else:
		godotsteam.request_lobby_list()

func close():
	if db:
		# Close database
		db.close()
		db = null

func _input(event):
	if game_params.is_event_cancel_action(event):
		_on_Back_pressed()
