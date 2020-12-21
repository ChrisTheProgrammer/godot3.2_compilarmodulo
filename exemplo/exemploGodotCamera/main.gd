extends Node2D

onready var nativeCamera = $VBoxContainer/picture/nativeCamera
onready var pictureReturned = $VBoxContainer/picture
onready var guiCamera = $VBoxContainer/guiCamera
onready var btnPreview = $VBoxContainer/btnPreview
onready var btnOpenNativeCamera = $VBoxContainer/btnOpenNativeCam
onready var btnForwardBack = $VBoxContainer/guiCamera/btnForwardBack

var facing = false
var is_open = true

func _ready():
# warning-ignore:return_value_discarded
	OS.request_permissions()
	nativeCamera.connect("picture_taken", self, "on_picture_taken")
	
func _on_btnTakePicture_pressed():
	guiCamera.hide()
	btnPreview.show()
	if nativeCamera.camera:
		nativeCamera.take_picture()

func _on_btnOpenNativeCam_pressed():
	_reset()
	if nativeCamera.camera and !is_open:
		nativeCamera.camera.setImageSize(pictureReturned.texture.get_size().x) # width / height ascpect ratio
		nativeCamera.camera.setImageRotated(90) # rotation
		nativeCamera.camera.openCamera()

func _on_btnPreview_pressed():
	if !nativeCamera.camera:
		nativeCamera._initialize()
	
	yield(get_tree().create_timer(1), "timeout")
	if nativeCamera.camera: 
		is_open = true
		nativeCamera.set_view_visibilty(true)
		guiCamera.show()
		btnPreview.hide()

func on_picture_taken(error, image_texture, _extras):
	if nativeCamera.camera:
		if error == nativeCamera.ERROR.NONE:
			pictureReturned.texture = image_texture
			
	guiCamera.hide()
	btnPreview.show()
	is_open = false
	nativeCamera.set_view_visibilty(false)

func _reset():
	pictureReturned.texture = ResourceLoader.load("res://camera.png")
	is_open = false
	nativeCamera.set_view_visibilty(false)

func _on_btnForwardBack_pressed():
	if nativeCamera.camera:
		nativeCamera.set_camera_facing(facing)
		facing = !facing
		
		if facing:
			btnForwardBack.text = "B" #back
		else:
			btnForwardBack.text = "F" #front

func _on_btnTakePreviewClose_pressed():
	if nativeCamera.camera:
		guiCamera.hide()
		btnPreview.show()
	_reset()
