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
	Flags      uint16  `json:"flags"`
	/*Enabled    bool    `json:"enabled"`
	Weapon        bool    `json:"weapon"`
	Players       bool    `json:"players"`
	Sentries      bool    `json:"sentries"`
	Dispensers    bool    `json:"dispensers"`
	Teleporters   bool    `json:"teleporters"`
	MedAmmo       bool    `json:"medammo"`
	ChristmasBall bool    `json:"christmasball"`*/
}

type ESP struct {
	Enabled bool `json:"enabled"`

	Box struct {
		Enabled bool   `json:"enabled"`
		Mode    string `json:"mode"` // modes: solid, outlined
	} `json:"box"`

	HealthBar struct {
		Enabled     bool       `json:"enabled"`
		TopColor    color.RGBA `json:"topcolor"`    // top color of the gradient
		BottomColor color.RGBA `json:"bottomcolor"` // bottom color of the gradient
	} `json:"healthbar"`

	Filter    uint8 `json:"filter"` // Entity filter; Player, Sentries, Dispensers, Teleporters, NPCs, Friends
	CondFlags uint8 `json:"conds"`
}
