extends Control
class_name PauseMenu

signal resumed
signal journal_pressed
signal restart_pressed
signal menu_pressed

@onready var panel: PanelContainer = $PanelContainer
@onready var slider: HSlider = $PanelContainer/VBox/VolumeRow/VolumeSlider

func _ready() -> void:
	UI.apply_button_style($PanelContainer/VBox/ContinueButton, "primary", 28)
	UI.apply_button_style($PanelContainer/VBox/JournalButton, "secondary", 24)
	UI.apply_button_style($PanelContainer/VBox/RestartButton, "secondary", 24)
	UI.apply_button_style($PanelContainer/VBox/MenuButton, "secondary", 24)
	UI.apply_button_style($PanelContainer/VBox/QuitButton, "danger", 24)
	UI.style($PanelContainer/VBox/Heading, 34, G.CYAN, G.f_retro)
	$PanelContainer/VBox/Heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.style($PanelContainer/VBox/VolumeRow/VolumeLabel, 24, G.CREAM)
	slider.value = G.volume
	slider.value_changed.connect(func(x): Sfx.set_volume(x))
	$PanelContainer/VBox/ContinueButton.pressed.connect(func(): resumed.emit())
	$PanelContainer/VBox/JournalButton.pressed.connect(func(): journal_pressed.emit())
	$PanelContainer/VBox/RestartButton.pressed.connect(func(): restart_pressed.emit())
	$PanelContainer/VBox/MenuButton.pressed.connect(func(): menu_pressed.emit())
	$PanelContainer/VBox/QuitButton.pressed.connect(func(): get_tree().quit())

func open() -> void:
	visible = true
	await get_tree().process_frame
	panel.position = (Vector2(960, 540) - panel.size / 2).round()

func close() -> void:
	visible = false
