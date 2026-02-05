local BAR_LENGTH = 20
local TOTAL_STEPS = 50
local LOAD_TEXT = "Loading client..."

local function renderBar(progress)
	local filled = math.floor(progress * BAR_LENGTH)
	return string.rep("#", filled) .. string.rep("-", BAR_LENGTH - filled)
end

print("Starting loader...")

for i = 1, TOTAL_STEPS do
	local progress = i / TOTAL_STEPS
	local percent = math.floor(progress * 100)

	local bar = renderBar(progress)

	print(string.format(
		"[%s] %d%% - %s",
		bar,
		percent,
		LOAD_TEXT
	))

	task.wait(0.05)
end

print("[####################] 100% - Done.")
print("Client loaded.")
