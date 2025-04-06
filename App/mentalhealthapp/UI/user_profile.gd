extends Node2D
class_name UserProfile

@onready var profile_container = $CanvasLayer/ProfileContainer

func _ready() -> void:
	if DataStorage.user_data["user_profile"]["gender"] != "" and DataStorage.user_data["user_profile"]["age"] > 0:
		show_profile_info()
	else:
		show_profile_setup()

func show_profile_setup():
	for child in profile_container.get_children():
		if child.name != "TitleLabel":  # Keep the title
			child.queue_free()
	var form = VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = "Profile Setup"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	form.add_child(title_label)
	
	var info_label = Label.new()
	info_label.text = "This information helps provide personalized insights."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(info_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	form.add_child(spacer)
	
	var gender_label = Label.new()
	gender_label.text = "Gender:"
	form.add_child(gender_label)
	
	var gender_options = OptionButton.new()
	gender_options.name = "gender_options"
	gender_options.add_item("Female", 0)
	gender_options.add_item("Male", 1)
	gender_options.add_item("Non-binary", 2)
	gender_options.add_item("Prefer not to say", 3)
	form.add_child(gender_options)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	form.add_child(spacer2)
	
	var age_label = Label.new()
	age_label.text = "Age:"
	form.add_child(age_label)
	
	var age_slider = HSlider.new()
	age_slider.name = "age_slider"
	age_slider.min_value = 13
	age_slider.max_value = 100
	age_slider.step = 1
	age_slider.value = 32
	form.add_child(age_slider)
	
	var age_value = Label.new()
	age_value.name = "age_value"
	age_value.text = "32"
	age_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	age_slider.connect("value_changed", Callable(self, "_on_age_changed").bind(age_value))
	form.add_child(age_value)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 30)
	form.add_child(spacer3)
	
	var save_button = Button.new()
	save_button.text = "Save Profile"
	save_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	save_button.connect("pressed", Callable(self, "_on_save_profile").bind(form))
	form.add_child(save_button)
	
	profile_container.add_child(form)

func show_profile_info():
	for child in profile_container.get_children():
		if child.name != "TitleLabel":  # Keep the title
			child.queue_free()
	
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = "Your Profile"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	info_container.add_child(title_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	info_container.add_child(spacer)
	
	var gender_label = Label.new()
	gender_label.text = "Gender: " + DataStorage.user_data["user_profile"]["gender"]
	gender_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(gender_label)
	
	var age_label = Label.new()
	age_label.text = "Age: " + str(DataStorage.user_data["user_profile"]["age"])
	age_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(age_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	info_container.add_child(spacer2)
	
	var edit_button = Button.new()
	edit_button.text = "Edit Profile"
	edit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	edit_button.connect("pressed", Callable(self, "show_profile_setup"))
	info_container.add_child(edit_button)
	profile_container.add_child(info_container)

func _on_age_changed(value, label):
	label.text = str(int(value))

func _on_save_profile(form):
	var gender_options = form.get_node("gender_options")
	var age_slider = form.get_node("age_slider")
	
	var gender = ""
	match gender_options.selected:
		0: gender = "Female"
		1: gender = "Male"
		2: gender = "Non-binary"
		3: gender = "Prefer not to say"
	var age = int(age_slider.value)
	
	DataStorage.set_user_profile(gender, age)
	show_profile_info() 
