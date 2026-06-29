@tool
extends SceneTree

func _init():
	print("--- GODOT EXPORT ERROR CHECKER ---")
	
	# Let's check the EditorSettings!
	# In Godot 4 editor mode, we can get EditorInterface
	# But we can also get the EditorSettings singleton directly from Engine or EditorSettings class
	var es = EditorInterface.get_editor_settings() if Engine.has_singleton("EditorInterface") else null
	if not es:
		# Try loading it as a resource or getting it via Engine
		es = Engine.get_singleton("EditorSettings")
		
	if es:
		print("EditorSettings found:")
		print("  android_sdk_path = ", es.get_setting("export/android/android_sdk_path"))
		print("  java_sdk_path = ", es.get_setting("export/android/java_sdk_path"))
		print("  debug_keystore = ", es.get_setting("export/android/debug_keystore"))
	else:
		print("EditorSettings NOT found.")
		
	quit()
