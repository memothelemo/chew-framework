local Players = game:GetService("Players")

-- selene: allow(undefined_variable)
---@diagnostic disable-next-line: undefined-global
local Chew = require(path.to.Chew)

local INITIAL_PLAYER_CASH = 0

local CashService = Chew.createSingleton {
	-- { [Player]: number }
	_storage = {}
}

function CashService:awardPlayer(player: Player, amount: number)
	assert(amount > 0, "Attempt to award player a cash with a negative number!")
	local cash = self._storage[player]
	if cash then
		self._storage[player] = cash + amount
	end
end

function CashService:_initPlayer(player: Player)
	if self._storage[player] == nil then
		self._storage[player] = INITIAL_PLAYER_CASH
	end
end

function CashService:onInit()
	Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self._storage[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(self.initPlayer, self, player)
	end
end

return CashService
