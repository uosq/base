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
						GroupV("Entity Filter",
							container.NewHBox(
								container.NewVBox(
									CreateToggleFlag8("Players", &settings.ESP.Filter, 0),
									CreateToggleFlag8("Weapons", &settings.ESP.Filter, 1),
									CreateToggleFlag8("Sentries", &settings.ESP.Filter, 2),
									CreateToggleFlag8("Dispensers", &settings.ESP.Filter, 3),
								),
								container.NewVBox(
									CreateToggleFlag8("Teleporters", &settings.ESP.Filter, 4),
									CreateToggleFlag8("ChristmasBall", &settings.ESP.Filter, 5),
									CreateToggleFlag8("MedKit / Ammo", &settings.ESP.Filter, 6),
								),
							),
						),

						GroupV("Condition Filter",
							container.NewHBox(
								container.NewVBox(
									CreateToggleFlag8("Cloaked", &settings.ESP.CondFilter, 0),
									CreateToggleFlag8("Ubercharged", &settings.ESP.CondFilter, 1),
									CreateToggleFlag8("Jarated", &settings.ESP.CondFilter, 2),
									CreateToggleFlag8("Kritz", &settings.ESP.CondFilter, 3),
								),

								container.NewVBox(
									CreateToggleFlag8("Milked", &settings.ESP.CondFilter, 4),
									CreateToggleFlag8("Overhealed", &settings.ESP.CondFilter, 5),
									CreateToggleFlag8("Sapped", &settings.ESP.CondFilter, 6),
									CreateToggleFlag8("Vaccinator Resist", &settings.ESP.CondFilter, 7),
								),
							),
						),
					),
				),

				GroupV("Glow",
					CreateToggle("Enabled", &settings.Glow.Enabled),
					CreateSliderStepped("Blurriness", &settings.Glow.Blurriness, 0, 30, 1.0),
					CreateSliderStepped("Stencil", &settings.Glow.Stencil, 0, 30, 1.0),
				),

				GroupV("ESP",
					CreateToggle("Enabled", &settings.ESP.Enabled),

					GroupV("Box",
						CreateToggle("Enabled", &settings.ESP.Box.Enabled),
						CreateList("Mode", []string{"Solid", "Outlined"}, &settings.ESP.Box.Mode, "Solid"),
					),

					GroupV("Health Bar",
						CreateToggle("Enabled", &settings.ESP.HealthBar.Enabled),
						CreateColorPickerButton("High Health Color", &settings.ESP.HealthBar.TopColor, window),
						CreateColorPickerButton("Low Health Color", &settings.ESP.HealthBar.BottomColor, window),
					),
				),
			),
		)),
	),
	)

	window.ShowAndRun()
}
