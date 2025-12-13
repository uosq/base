---@class Settings
---@field aimbot Aimbot
---@field glow Glow

---@class Aimbot
---@field enabled boolean
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

---@class Melee
---@field enabled boolean
---@field rage boolean

---@class Glow
---@field stencil integer
---@field blurriness integer
---@field enabled boolean
---@field flags integer
----@field weapon boolean
----@field players boolean
----@field sentries boolean
----@field dispensers boolean
----@field teleporters boolean
----@field medammo boolean
----@field viewmodel boolean
----@field christmasball boolean