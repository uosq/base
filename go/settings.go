package main

import "image/color"

type Settings struct {
	Aimbot Aimbot `json:"aimbot"`
	Glow   Glow   `json:"glow"`
	ESP    ESP    `json:"esp"`
}

type Aimbot struct {
	Enabled      bool `json:"enabled"`
	FovIndicator bool `json:"fovindicator"`

	Hitscan struct {
		Enabled   bool    `json:"enabled"`
		Fov       float64 `json:"fov"`
		Autoshoot bool    `json:"autoshoot"`
		Key       string  `json:"key"`
	} `json:"hitscan"`

	Proj struct {
		Enabled              bool    `json:"enabled"`
		Fov                  float64 `json:"fov"`
		Autoshoot            bool    `json:"autoshoot"`
		Key                  string  `json:"key"`
		MaxSimTime           float64 `json:"maxsimtime"`
		SelfDamage           bool    `json:"selfdamage"`
		CompensateDetonation bool    `json:"compensate"`
	} `json:"proj"`

	Melee struct {
		Enabled bool `json:"enabled"`
		Rage    bool `json:"rage"`
	} `json:"melee"`
}

type Glow struct {
	Stencil    float64 `json:"stencil"`
	Blurriness float64 `json:"blurriness"`
	Enabled    bool    `json:"enabled"`
	/*Enabled    bool    `json:"enabled"` 0
	Weapon        bool    `json:"weapon"` 1
	Players       bool    `json:"players"` 2
	Sentries      bool    `json:"sentries"` 3
	Dispensers    bool    `json:"dispensers"` 4
	Teleporters   bool    `json:"teleporters"` 5
	MedAmmo       bool    `json:"medammo"` 6
	ChristmasBall bool    `json:"christmasball"` 7*/
}

type ESP struct {
	Enabled bool `json:"enabled"`

	Colors struct {
		RedTeam  color.RGBA `json:"redteam"`
		BlueTeam color.RGBA `json:"blueteam"`
	} `json:"colors"`

	Box struct {
		Enabled bool   `json:"enabled"`
		Mode    string `json:"mode"` // modes: solid, outlined
	} `json:"box"`

	HealthBar struct {
		Enabled     bool       `json:"enabled"`
		TopColor    color.RGBA `json:"topcolor"`    // top color of the gradient
		BottomColor color.RGBA `json:"bottomcolor"` // bottom color of the gradient
	} `json:"healthbar"`

	Filter     uint8 `json:"filter"` // Entity filter: Player, Sentries, Dispensers, Teleporters, NPCs, Friends, Projectiles, Objective
	CondFilter uint8 `json:"conds"`  // Condition filter: Cloaked, Jarated, Ubercharged, Kritz, Milked, Overhealed, Sapped, Vacc Resistance
}
