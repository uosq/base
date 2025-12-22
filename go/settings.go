package main

import "image/color"

type Settings struct {
	Aimbot  Aimbot  `json:"aimbot"`
	Visuals Visuals `json:"visuals"`
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

type Visuals struct {
	Enabled bool `json:"enabled"`

	ESP struct {
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
	} `json:"esp"`

	Glow struct {
		Stencil    float64 `json:"stencil"`
		Blurriness float64 `json:"blurriness"`
		Enabled    bool    `json:"enabled"`
	} `json:"glow"`

	Chams struct {
		Enabled bool    `json:"enabled"`
		Alpha   float64 `json:"alpha"`
	} `json:"chams"`

	Colors struct {
		RedTeam       color.RGBA `json:"redteam"`
		BlueTeam      color.RGBA `json:"blueteam"`
		AmmoPack      color.RGBA `json:"ammopack"`
		MedKit        color.RGBA `json:"medkit"`
		SmissmassBall color.RGBA `json:"cphysicsprop"`
		Weapon        color.RGBA `json:"weapon"`
		Friend        color.RGBA `json:"friend"`
		Priority      color.RGBA `json:"priority"`
		AimTarget     color.RGBA `json:"aimtarget"`
		LocalPlayer   color.RGBA `json:"localplayer"`
	} `json:"colors"`

	IgnoreFilter uint8 `json:"ignorefilter"` // Cloaked,
	Filter       uint8 `json:"filter"`       // Entity filter: Player, Sentries, Dispensers, Teleporters, NPCs, Friends, Projectiles, Objective
	CondFilter   uint8 `json:"conds"`        // Condition filter: Cloaked, Jarated, Ubercharged, Kritz, Milked, Overhealed, Sapped, Vacc Resistance
	OptionFilter uint8 `json:"options"`      // Text: Name, Class, Distance, Ubercharge %, Weapon, SteamID, Health, ??
}
