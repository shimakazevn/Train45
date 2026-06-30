import re
# Disable GodotSteam
content = open('project.godot').read()
content = re.sub(r'"res://addons/godotsteam/[^"]*"', '', content)
content = re.sub(r',\s*,', ',', content)
content = re.sub(r'\(\s*,', '(', content)
content = re.sub(r',\s*\)', ')', content)
open('project.godot', 'w').write(content)

# Patch Team ID
presets = open('export_presets.cfg').read()
presets = re.sub(r'codesign/team_id="[^"]*"', 'codesign/team_id="H6H365832M"', presets)
if 'application/app_store_team_id=' in presets:
    presets = re.sub(r'application/app_store_team_id="[^"]*"', 'application/app_store_team_id="H6H365832M"', presets)
else:
    presets = presets.replace('codesign/team_id="H6H365832M"', 'codesign/team_id="H6H365832M"\napplication/app_store_team_id="H6H365832M"')
open('export_presets.cfg', 'w').write(presets)
