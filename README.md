## Chew
A minimalistic game framework without any bloated libraries.

```lua
local Players = game:GetService("Players")
local Chew = require(path.to.Chew)

-- Creates a singleton
local MyService = Chew.createSingleton()

function MyService:onInit()
	Players.PlayerAdded:Connect(function(player)
		print("Hi, " .. player.Name)
	end)
end

function MyService:onStart()
	print("Hello world!")
end

Chew.ignite()
```
