package main

import (
	"encoding/json"
	"log"
	"net/http"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
)

var settings Settings

func Handle_GetSettings(w http.ResponseWriter, r *http.Request) {
	encoded, err := json.Marshal(settings)
	if err != nil {
		log.Fatal(err)
		return
	}

	w.Write(encoded)
}

func main() {
	http.HandleFunc("/", Handle_GetSettings)
	go func() { log.Fatal(http.ListenAndServe(":8080", nil)) }()

	app := app.NewWithID("navet.com/base")
	app.Settings().SetTheme(&myTheme{})
	window := app.NewWindow("Base")
	window.Resize(fyne.NewSize(600, 400))

	window.SetContent(container.NewAppTabs(
		container.NewTabItem("Aimbot", container.NewVScroll(
			container.NewVBox(
				GroupV("General",
					CreateToggle("Enabled", &settings.Aimbot.Enabled),
					CreateToggle("FOV Indicator", &settings.Aimbot.FovIndicator),
				),

				GroupV("Hitscan",
					CreateToggle("Enabled", &settings.Aimbot.Hitscan.Enabled),
					CreateToggle("Autoshoot", &settings.Aimbot.Hitscan.Autoshoot),
					CreateKeySelection("Key", &settings.Aimbot.Hitscan.Key),
					CreateSlider("FOV", &settings.Aimbot.Hitscan.Fov, 0, 180),
				),

				GroupV("Projectile",
					CreateToggle("Enabled", &settings.Aimbot.Proj.Enabled),
					CreateToggle("Autoshoot", &settings.Aimbot.Proj.Autoshoot),
					CreateKeySelection("Key", &settings.Aimbot.Proj.Key),
					CreateSlider("FOV", &settings.Aimbot.Proj.Fov, 0, 180),
					CreateSlider("Max Simulation Time", &settings.Aimbot.Proj.MaxSimTime, 0, 5),
				),
			),
		)),

		container.NewTabItem("Visuals", container.NewVScroll(
			container.NewVBox(
				container.NewBorder(nil, nil, nil, nil,
					container.NewGridWithColumns(2,
						GroupH("Entity Filter",
							container.NewVBox(
								CreateToggleFlag8("Players", &settings.Visuals.Filter, 0),
								CreateToggleFlag8("Weapons", &settings.Visuals.Filter, 1),
								CreateToggleFlag8("Sentries", &settings.Visuals.Filter, 2),
								CreateToggleFlag8("Dispensers", &settings.Visuals.Filter, 3),
							),
							container.NewVBox(
								CreateToggleFlag8("Teleporters", &settings.Visuals.Filter, 4),
								CreateToggleFlag8("ChristmasBall", &settings.Visuals.Filter, 5),
								CreateToggleFlag8("MedKit / Ammo", &settings.Visuals.Filter, 6),
							),
						),

						GroupH("Condition Filter",
							container.NewVBox(
								CreateToggleFlag8("Cloaked", &settings.Visuals.CondFilter, 0),
								CreateToggleFlag8("Ubercharged", &settings.Visuals.CondFilter, 1),
								CreateToggleFlag8("Jarated", &settings.Visuals.CondFilter, 2),
								CreateToggleFlag8("Kritz", &settings.Visuals.CondFilter, 3),
							),

							container.NewVBox(
								CreateToggleFlag8("Milked", &settings.Visuals.CondFilter, 4),
								CreateToggleFlag8("Overhealed", &settings.Visuals.CondFilter, 5),
								CreateToggleFlag8("Sapped", &settings.Visuals.CondFilter, 6),
								CreateToggleFlag8("Vaccinator Resist", &settings.Visuals.CondFilter, 7),
							),
						),
					),
				),

				GroupV("Glow",
					CreateToggle("Enabled", &settings.Visuals.Glow.Enabled),
					CreateSliderStepped("Blurriness", &settings.Visuals.Glow.Blurriness, 0, 30, 1.0),
					CreateSliderStepped("Stencil", &settings.Visuals.Glow.Stencil, 0, 30, 1.0),
				),

				GroupV("ESP",
					CreateToggle("Enabled", &settings.Visuals.ESP.Enabled),

					GroupH("Options",
						container.NewGridWithColumns(4,
							CreateToggleFlag8("Name", &settings.Visuals.OptionFilter, 0),
							CreateToggleFlag8("Class", &settings.Visuals.OptionFilter, 1),

							CreateToggleFlag8("Health", &settings.Visuals.OptionFilter, 2),
							CreateToggleFlag8("Distance", &settings.Visuals.OptionFilter, 3),

							CreateToggleFlag8("Ubercharge", &settings.Visuals.OptionFilter, 4),
							CreateToggleFlag8("Weapon", &settings.Visuals.OptionFilter, 5),

							CreateToggleFlag8("SteamID", &settings.Visuals.OptionFilter, 6),
						),

						// still have 1 bit left
					),

					GroupV("Box",
						CreateToggle("Enabled", &settings.Visuals.ESP.Box.Enabled),
						CreateList("Mode", []string{"Solid", "Outlined"}, &settings.Visuals.ESP.Box.Mode, "Solid"),
					),

					GroupV("Health Bar",
						CreateToggle("Enabled", &settings.Visuals.ESP.HealthBar.Enabled),
						CreateColorPickerButton("High Health Color", &settings.Visuals.ESP.HealthBar.TopColor, window),
						CreateColorPickerButton("Low Health Color", &settings.Visuals.ESP.HealthBar.BottomColor, window),
					),
				),

				GroupV("Chams",
					CreateToggle("Enabled", &settings.Visuals.Chams.Enabled),
					CreateSlider("Alpha (%)", &settings.Visuals.Chams.Alpha, 0, 100),
				),

				GroupV("Colors",
					CreateColorPickerButton("RED Team", &settings.Visuals.Colors.RedTeam, window),
					CreateColorPickerButton("BLU Team", &settings.Visuals.Colors.BlueTeam, window),
					CreateColorPickerButton("Aim Target", &settings.Visuals.Colors.AimTarget, window),
					CreateColorPickerButton("Ammo Pack", &settings.Visuals.Colors.AmmoPack, window),
					CreateColorPickerButton("Friend", &settings.Visuals.Colors.Friend, window),
					CreateColorPickerButton("LocalPlayer", &settings.Visuals.Colors.LocalPlayer, window),
					CreateColorPickerButton("Med Kit", &settings.Visuals.Colors.MedKit, window),
					CreateColorPickerButton("Priority", &settings.Visuals.Colors.Priority, window),
					CreateColorPickerButton("Smissmass Ball", &settings.Visuals.Colors.SmissmassBall, window),
					CreateColorPickerButton("Weapon", &settings.Visuals.Colors.Weapon, window),
				),
			),
		)),
	),
	)

	window.ShowAndRun()
}
