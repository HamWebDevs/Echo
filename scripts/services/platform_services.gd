class_name PlatformServices
extends Node

signal store_changed
signal message(text: String)

var native: Object
var supporter := false
var entitlement_known := false
var price := ""
var busy := false
var configured := false
var analytics_enabled := false

func _ready() -> void:
	if not Engine.has_singleton("EchoServices"):
		return
	native = Engine.get_singleton("EchoServices")
	native.connect("offer_loaded", _on_offer)
	native.connect("entitlement_changed", _on_entitlement)
	native.connect("purchase_state", _on_purchase_state)
	if FileAccess.file_exists("res://config/services.json"):
		var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/services.json"))
		if config is Dictionary:
			configured = native.configure_services(JSON.stringify(config))

func _on_offer(local_price: String) -> void:
	price = local_price
	store_changed.emit()

func _on_entitlement(active: bool) -> void:
	entitlement_known = true
	supporter = active
	store_changed.emit()

func _on_purchase_state(state: String, detail: String) -> void:
	busy = state == "pending"
	if not detail.is_empty():
		message.emit(detail)
	store_changed.emit()

func purchase() -> void:
	if native == null or not configured or price.is_empty():
		message.emit("Purchases are unavailable in this build.")
		return
	busy = true
	store_changed.emit()
	native.purchase_supporter()

func restore() -> void:
	if native == null or not configured:
		message.emit("Restore is available in the Google Play release.")
		return
	busy = true
	store_changed.emit()
	native.restore_purchases()

func set_analytics(enabled: bool) -> void:
	analytics_enabled = enabled
	if native != null:
		native.set_analytics_enabled(enabled)

func track(event_name: String, properties: Dictionary = {}) -> void:
	if analytics_enabled and native != null:
		native.log_event(event_name, JSON.stringify(properties))

func share_image(image: Image) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(image.save_png_to_buffer(), "echo-score.png", "image/png")
		message.emit("Your score card is ready to share.")
		return
	var path := "user://echo-score.png"
	if image.save_png(path) != OK:
		message.emit("Could not save your score card. Please try again.")
		return
	var absolute := ProjectSettings.globalize_path(path)
	if native != null:
		native.share_score(absolute)
	else:
		DisplayServer.clipboard_set(absolute)
		message.emit("Score card saved. Its file path is on your clipboard.")

const INVITE_URL := "https://github.com/HamWebDevs/Echo/releases"
const INVITE_TEXT := "I made a mess of little copycats. Can you outrun yours? Play ECHO for Android: " + INVITE_URL

func share_invite() -> void:
	if native != null:
		native.share_invite()
	elif OS.has_feature("web"):
		# Called directly by a button gesture, so browser sharing retains activation.
		JavaScriptBridge.eval("navigator.share ? navigator.share({title:'ECHO',text:'Dodge your past. Pop your copycats.',url:'https://github.com/HamWebDevs/Echo/releases'}).catch(()=>{}) : navigator.clipboard.writeText('https://github.com/HamWebDevs/Echo/releases').catch(()=>window.open('https://github.com/HamWebDevs/Echo/releases','_blank'))")
	else:
		DisplayServer.clipboard_set(INVITE_TEXT)
		message.emit("Invite link copied. Send it to a friend!")
