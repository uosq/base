package main

type Settings struct {
	Aimbot Aimbot `json:"aimbot"`
	Glow   Glow   `json:"glow"`
}

type Aimbot struct {
	Enabled bool       `json:"enabled"`
	Hitscan AimHitscan `json:"hitscan"`
	Proj    AimProj    `json:"proj"`
	Melee   AimMelee   `json:"melee"`
}

type AimHitscan struct {
	Enabled   bool    `json:"enabled"`
	Fov       float64 `json:"fov"`
	Autoshoot bool    `json:"autoshoot"`
	Key       string  `json:"key"`
}

type AimProj struct {
	Enabled    bool    `json:"enabled"`
	Fov        float64 `json:"fov"`
	Autoshoot  bool    `json:"autoshoot"`
	Key        string  `json:"key"`
	MaxSimTime float64 `json:"maxsimtime"`
}

type AimMelee struct {
	Enabled bool `json:"enabled"`
	Rage    bool `json:"rage"`
}

type Glow struct {
	Stencil       float64 `json:"stencil"`
	Blurriness    float64 `json:"blurriness"`
	Enabled       bool    `json:"enabled"`
	Weapon        bool    `json:"weapon"`
	Players       bool    `json:"players"`
	Sentries      bool    `json:"sentries"`
	Dispensers    bool    `json:"dispensers"`
	Teleporters   bool    `json:"teleporters"`
	MedAmmo       bool    `json:"medammo"`
	ViewModel     bool    `json:"viewmodel"`
	ChristmasBall bool    `json:"christmasball"`
}
