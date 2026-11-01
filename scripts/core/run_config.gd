class_name RunConfig
extends RefCounted

const RULES_VERSION := 1
var mode := "endless"
var seed_value: int = 1
var daily_date := ""
var tutorial := false

static func daily(date: String) -> RunConfig:
	var config := RunConfig.new()
	config.mode = "daily"
	config.daily_date = date
	config.seed_value = ("echo:%d:%s" % [RULES_VERSION, date]).sha256_text().substr(0, 12).hex_to_int()
	return config

static func endless(seed_number: int) -> RunConfig:
	var config := RunConfig.new()
	config.seed_value = seed_number
	return config

static func utc_date() -> String:
	return Time.get_date_string_from_system(true)

func record_key() -> String:
	return "%s:v%d" % [daily_date, RULES_VERSION]
