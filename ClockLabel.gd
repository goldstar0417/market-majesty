extends Label

var elapsed_time := 0.0

const SECONDS_PER_MINUTE = 60
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const DAYS_PER_MONTH = 30
const MONTHS_PER_YEAR = 12
const SEASONS = {
	"Winter": [12, 1, 2],
	"Spring": [3, 4, 5],
	"Summer": [6, 7, 8],
	"Autumn": [9, 10, 11]
}

var snow_particles : GPUParticles2D
var rain_particles : GPUParticles2D
var current_season = ""
var canvas_modulate : CanvasModulate

func _ready():
	snow_particles = get_parent().get_parent().get_node("SnowParticles")
	rain_particles = get_parent().get_parent().get_node("RainParticles")
	canvas_modulate = get_parent().get_parent().get_node("CanvasModulate")

func _process(delta):
	elapsed_time += delta * 10000

	var total_seconds = int(elapsed_time)
	var seconds = total_seconds % SECONDS_PER_MINUTE
	var total_minutes = total_seconds / SECONDS_PER_MINUTE
	var minutes = total_minutes % MINUTES_PER_HOUR
	var total_hours = total_minutes / MINUTES_PER_HOUR
	var hours = total_hours % HOURS_PER_DAY
	var total_days = total_hours / HOURS_PER_DAY
	var days = (total_days % DAYS_PER_MONTH) + 1
	var total_months = total_days / DAYS_PER_MONTH
	var months = (total_months % MONTHS_PER_YEAR) + 1

	var season = get_season(months)
	var day_night = "Day" if hours >= 6 and hours < 18 else "Night"

	text = "%s | %s | Month:%d Day:%d %02d:%02d:%02d" % [
		season, day_night, months, days, hours, minutes, seconds
	]
	update_canvas_shade(hours, delta)

	if season != current_season:
		current_season = season
		update_weather(season)

func get_season(month):
	for season_name in SEASONS:
		if month in SEASONS[season_name]:
			return season_name
	return "Unknown"

func update_weather(current_season):
	var wind_x = randf_range(-100, 100) # Random wind between left/right each season

	match current_season:
		"Winter":
			var snow_material = snow_particles.process_material as ParticleProcessMaterial
			if snow_material:
				snow_material.gravity = Vector3(wind_x, 20, 0)
			snow_particles.emitting = true
			rain_particles.emitting = false
		"Spring":
			var rain_material = rain_particles.process_material as ParticleProcessMaterial
			if rain_material:
				rain_material.gravity = Vector3(wind_x, 300, 0)
			snow_particles.emitting = false
			rain_particles.emitting = true
		_:
			snow_particles.emitting = false
			rain_particles.emitting = false

var target_modulate_color = Color(0,0,0,1)

func update_canvas_shade(hours, delta):
	if hours >= 5 and hours <= 7:
		target_modulate_color = Color(0.8, 0.7, 0.6) # Early Morning
	elif hours >= 8 and hours <= 11:
		target_modulate_color = Color(1.0, 0.9, 0.8) # Late Morning
	elif hours >= 12 and hours <= 14:
		target_modulate_color = Color(1.0, 1.0, 1.0) # Noon
	elif hours >= 15 and hours <= 17:
		target_modulate_color = Color(1.0, 0.95, 0.8) # Afternoon
	elif hours >= 18 and hours <= 20:
		target_modulate_color = Color(0.6, 0.5, 0.7) # Evening
	else:
		target_modulate_color = Color(0.3, 0.3, 0.5) # Night

	# Smooth transition
	canvas_modulate.color = canvas_modulate.color.lerp(target_modulate_color, 1)
