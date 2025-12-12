package main

type Settings struct {
	Aimbot Aimbot `json:"aimbot"`
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
