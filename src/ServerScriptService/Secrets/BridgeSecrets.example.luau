--!strict
--[[
	Copy to BridgeSecrets.luau (gitignored) and fill production URLs.
	Clawdi vault keys: utopia/BRIDGE_LOG_ANALYZER_URL, utopia/BRIDGE_FAN_SCAN_URL, utopia/BRIDGE_KEY
]]
	return {
	BRIDGE_KEY = "",
	LOG_ANALYZER_URL = "http://127.0.0.1:8011/utopia/log-analyzer",
	FAN_SCAN_URL = "http://127.0.0.1:8011/utopia/fan-scan",
	SOCIAL_NOTIFY_PUSH_URL = "http://127.0.0.1:8011/utopia/social-notify/push",
	CREATOR_PAYOUT_PUSH_URL = "http://127.0.0.1:8011/utopia/creator-payout/push",
	CREATOR_PAYOUT_SYNC_URL = "http://127.0.0.1:8011/utopia/creator-payout/sync",
}
