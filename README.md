## Chew
A minimalistic game framework inspired by
<a href="https://github.com/rbxts-flamework/core">Flamework</a> and
<a href="https://github.com/Sleitnick/Knit">Knit</a> 

It has no any bloated libraries *(provided by some frameworks)* you don't need.

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
