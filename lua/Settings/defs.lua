---@class Settings
---@field aimbot Aimbot
---@field visuals Visuals

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

---@class ColorRGBA
---@field R integer
---@field G integer
---@field B integer
---@field A integer

---@class VisualsESPBox
---@field enabled boolean
---@field mode "Solid"|"Outlined"

---@class VisualsESPHealthBar
---@field enabled boolean
---@field topcolor ColorRGBA
---@field bottomcolor ColorRGBA

---@class VisualsESP
---@field enabled boolean
---@field box VisualsESPBox
---@field healthbar VisualsESPHealthBar
---@field options integer # uint8 bitmask Name, Class, Distance, Ubercharge %, Weapon, SteamID, Health, ??
---@field ignorecloaked boolean

---@class VisualsGlow
---@field stencil number
---@field blurriness number
---@field enabled boolean

---@class VisualsColors
---@field redteam ColorRGBA
---@field blueteam ColorRGBA
---@field ammopack ColorRGBA
---@field medkit ColorRGBA
---@field cphysicsprop ColorRGBA
---@field weapon ColorRGBA
---@field friend ColorRGBA
---@field priority ColorRGBA
---@field aimtarget ColorRGBA
---@field localplayer ColorRGBA

---@class VisualsChams
---@field enabled boolean
---@field alpha number
---@field always boolean

---@class Visuals
---@field enabled boolean
---@field esp VisualsESP
---@field glow VisualsGlow
---@field chams VisualsChams
---@field colors VisualsColors
---@field ignorefilter integer # uint8 bitmask
---@field filter integer # uint8 bitmask (Players, Buildings, NPCs, Projectiles, Objectives, etc.)
---@field conds integer # uint8 bitmask (Cloaked, Jarated, Ubercharged, Kritz, Milked, Overhealed, Sapped, Vacc Resist)