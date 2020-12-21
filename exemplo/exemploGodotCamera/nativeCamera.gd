extends Control

export var draw_camera_splash = true setget set_draw_camera_splash
export(int, 1, 10) var image_resolution := 10 setget set_image_resolution
export(bool) var camera_facing := false setget set_camera_facing
export(int, "Off", "Auto", "On", "Red Eye", "Torch") var flash_mode := 1 setget set_flash_mode
export var pinch_to_zoom := true setget set_pinch_to_zoom
export var face_recognition := true setget set_face_recognition
export var face_recognition_bound_color := Color.white setget set_face_recognition_bound_color
export(int, "Rect", "Circle") var face_recognition_bound_shape := 0 setget set_face_recognition_bound_shape
export(int, 1, 100) var face_recognition_bound_line_size := 5 setget set_face_recognition_bound_line_size
export(int, "Auto", "HDR", "Portrait", "Landscape", "Night", "Sunset") var scene_mode := 0 setget set_scene_mode
export(int, "Auto", "Incandesent", "Flourescent", "Daylight", "Twilight", "Shade") var white_balanace := 0 setget set_white_balanace
export(int, "None", "Mono", "Negative", "Solarize", "Sepia") var color_effect := 0 setget set_color_effect

const PARAMETER_IMAGE_QUALITY = "param_image_quality";
const PARAMETER_IMAGE_RESOLUTION = "param_image_resolution";
const PARAMETER_FLASH_MODE = "param_flash_mode";
const PARAMETER_ENABLE_SHUTTER_SOUND = "param_enable_shutter_sound";
const PARAMETER_PITCH_TO_ZOOM = "param_pitch_to_zoom";
const PARAMETER_FACE_RECOGNITION = "param_face_recognition";
const PARAMETER_FACE_RECOGNITION_BOUND_COLOR = "param_face_recognition_bound_color";
const PARAMETER_FACE_RECOGNITION_BOUND_SHAPE = "param_face_recognition_bound_shape";
const PARAMETER_FACE_RECOGNITION_BOUND_LINE_SIZE = "param_face_recognition_bound_line_size";
const PARAMETER_SCENE_MODE = "param_scene_mode";
const PARAMETER_WHITE_BALANCE = "param_white_balance";
const PARAMETER_COLOR_EFFECT = "param_color_effect";

var camera = null
var node: Control

var is_initialized : bool = false setget _set_blank
var camera_permission_granted = false setget _set_blank, _get_blank

enum ERROR {
	NONE = 0,
	FATAL_ERROR = 1,
	OUT_OF_MEMORY = 2,
	MININUM_NUMBER_OF_FACE_NOT_DETECTED = 3
}

signal picture_taken(_cameraError, _texture, _faces)

const ParameterSerializer = preload("res://parameter_serializer.gd")

func _initialize():
	pass
	if camera: return
	if(Engine.has_singleton("GodotCamera")):
		camera = Engine.get_singleton("GodotCamera")
		if camera:
			var r : Rect2 = self.get_global_rect()
			var instanse_id = self.get_instance_id()
			
			var result = camera.setCameraCallbackId(instanse_id, true, ParameterSerializer.serialize(_get_parameters()), int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), self.visible)
	
			if result == true:
				print('OK')
			else:
				camera = null
				print('null')

func _base64texture(image64):
	var image = Image.new()
	image.load_png_from_buffer(Marshalls.base64_to_raw(image64))
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _on_GodotCamera_success(_fileName):
	self.emit_signal("picture_taken", 
	ERROR.NONE, 
	_base64texture(_fileName),
	null)

func _set_camera_features_(_features):
	prints(_features)

func _on_picture_taken_(camera_error_code, data, detectedFacesExtra):
	if camera_error_code == ERROR.NONE:
		var _detectedFacesExtra = ParameterSerializer.unserialize(detectedFacesExtra);

		var image : Image = Image.new()
		var err = image.load_jpg_from_buffer(data)

		if err != OK:
			print("An error occured while loading camera image texture!")
		else:
			var texture = ImageTexture.new()
			texture.create_from_image(image, 16)
			self.emit_signal("picture_taken", ERROR.NONE, texture,
			{
				"faces": _detectedFacesExtra.values()
			})

			
		if camera:
			camera.refreshCameraPreview(self.get_instance_id());
		pass

func set_view_visibilty(visible: bool):
	if camera:
		camera.setViewVisibility(self.get_instance_id(), visible)

func destroy_view():
	camera.destroyView(self.get_instance_id())
	camera = null

func set_camera_facing(back_facing: bool):
	camera.setPreviewCameraFacing(self.get_instance_id(), back_facing)

func set_parameter(what: String, value):
	if value is int:
		camera.setViewParameterInt(self.get_instance_id(), what, value);
	elif value is bool:
		camera.setViewParameterBool(self.get_instance_id(), what, value);
	elif value is String:
		camera.setViewParameterString(self.get_instance_id(), what, value);
	else:
		prints("set_parameter: It's a non supported type");
	pass

func resize_view(rect: Rect2):
	camera.resizeView(self.get_instance_id(), int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y))

func take_picture(minimum_number_of_face = 0):
	camera.takePicture(self.get_instance_id(), minimum_number_of_face)

func _set_blank(value):
	pass

func _get_blank():
	pass

func _get_parameters()->Dictionary:
	return {
		self.PARAMETER_IMAGE_RESOLUTION: image_resolution,
		self.PARAMETER_FLASH_MODE: flash_mode,
		self.PARAMETER_PITCH_TO_ZOOM: pinch_to_zoom,
		self.PARAMETER_FACE_RECOGNITION: face_recognition,
		self.PARAMETER_FACE_RECOGNITION_BOUND_COLOR: face_recognition_bound_color.to_html(),
		self.PARAMETER_FACE_RECOGNITION_BOUND_SHAPE: face_recognition_bound_shape,
		self.PARAMETER_FACE_RECOGNITION_BOUND_LINE_SIZE: face_recognition_bound_line_size,
		self.PARAMETER_SCENE_MODE: scene_mode,
		self.PARAMETER_WHITE_BALANCE: white_balanace,
		self.PARAMETER_COLOR_EFFECT: color_effect
	}

func set_draw_camera_splash(value):
	draw_camera_splash = value;
	update();
	pass

func set_image_resolution(value):
	image_resolution = value;
	if camera != null:
		camera.set_parameter(self.PARAMETER_IMAGE_RESOLUTION, value);
	pass

func set_flash_mode(value):
	flash_mode = value;
	if camera != null:
		camera.set_parameter(self.PARAMETER_FLASH_MODE, flash_mode);
	pass

func set_pinch_to_zoom(value):
	pinch_to_zoom = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_PITCH_TO_ZOOM, value)
	pass

func set_face_recognition(value):
	face_recognition = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_FACE_RECOGNITION, value)
	pass

func set_face_recognition_bound_color(value):
	face_recognition_bound_color = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_FACE_RECOGNITION_BOUND_COLOR, value.to_html())
	pass

func set_face_recognition_bound_shape(value):
	face_recognition_bound_shape = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_FACE_RECOGNITION_BOUND_SHAPE, value)
	pass

func set_face_recognition_bound_line_size(value):
	face_recognition_bound_line_size = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_FACE_RECOGNITION_BOUND_LINE_SIZE, value)
	pass

func set_scene_mode(value):
	scene_mode = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_SCENE_MODE, value)
	pass

func set_white_balanace(value):
	white_balanace = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_WHITE_BALANCE, value)
	pass

func set_color_effect(value):
	color_effect = value
	if camera != null:
		camera.set_parameter(self.PARAMETER_COLOR_EFFECT, value)
	pass
