---@class Settings
---@field aimbot Aimbot
---@field glow Glow
---@field esp ESP

---@class Aimbot
---@field enabled boolean
---@field fovindicator boolean
---@field hitscan Hitscan
---@field proj Projectile
---@field melee Melee

---@class Hitscan
---@field enabled boolean
---@field fov number
---@field autoshoot boolean
---@field key string

---@class Projectile
---@field enabled boolean
---@field fov number
---@field autoshoot boolean
---@field key string
---@field maxsimtime number
---@field selfdamage boolean
---@field compensate boolean

---@class Melee
---@field enabled boolean
---@field rage boolean

---@class Glow
---@field stencil integer
---@field blurriness integer
---@field enabled boolean
----@field weapon boolean
----@field players boolean
----@field sentries boolean
----@field dispensers boolean
----@field teleporters boolean
----@field medammo boolean
----@field viewmodel boolean
----@field christmasball boolean

---@class ColorRGBA
---@field R integer
---@field G integer
---@field B integer
---@field A integer

---@class ESP_Color
---@field redteam ColorRGBA
---@field blueteam ColorRGBA
---@field aimtarget ColorRGBA
---@field localplayer ColorRGBA

---@class ESP_Box
---@field enabled boolean
---@field mode "Solid"|"Outlined"

---@class ESP_HealthBar
---@field enabled boolean
---@field topcolor ColorRGBA --- top color of the gradient
---@field bottomcolor ColorRGBA --- bottom color of the gradient

---@class ESP
---@field enabled boolean
---@field box ESP_Box
---@field healthbar ESP_HealthBar
---@field filter integer --- uint8: entity filter bitmask
---@field conds integer --- uint8: condition filter bitmask
---@field colors ESP_Color