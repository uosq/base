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

	app := app.New()
	app.Settings().SetTheme(&myTheme{})
	window := app.NewWindow("Base")
	window.Resize(fyne.NewSize(600, 400))

	window.SetContent(container.NewAppTabs(
		container.NewTabItem("Aimbot", container.NewVScroll(
			container.NewVBox(
				Group("General",
					CreateToggle("Enabled", &settings.Aimbot.Enabled),
					CreateToggle("FOV Indicator", &settings.Aimbot.FovIndicator),
				),

				Group("Hitscan",
					CreateToggle("Enabled", &settings.Aimbot.Hitscan.Enabled),
					CreateToggle("Autoshoot", &settings.Aimbot.Hitscan.Autoshoot),
					CreateKeySelection("Key", &settings.Aimbot.Hitscan.Key),
					CreateSlider("FOV", &settings.Aimbot.Hitscan.Fov, 0, 180),
				),

				Group("Projectile",
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
				Group("Entity Filter",
					container.NewHBox(
						container.NewVBox(
							CreateToggleFlag("Players", &settings.Glow.Flags, 1),
							CreateToggleFlag("Weapons", &settings.Glow.Flags, 2),
							CreateToggleFlag("Sentries", &settings.Glow.Flags, 3),
							CreateToggleFlag("Dispensers", &settings.Glow.Flags, 4),
						),
						container.NewVBox(
							CreateToggleFlag("Teleporters", &settings.Glow.Flags, 5),
							CreateToggleFlag("ChristmasBall", &settings.Glow.Flags, 6),
							CreateToggleFlag("MedKit / Ammo", &settings.Glow.Flags, 7),
						),
					),
				),

				Group("Glow",
					CreateToggleFlag("Enabled", &settings.Glow.Flags, 0),
					CreateSliderStepped("Blurriness", &settings.Glow.Blurriness, 0, 30, 1.0),
					CreateSliderStepped("Stencil", &settings.Glow.Stencil, 0, 30, 1.0),
				),

				Group("ESP",
					CreateToggle("Enabled", &settings.ESP.Enabled),

					Group("Box",
						CreateToggle("Enabled", &settings.ESP.Box.Enabled),
						CreateList("Mode", []string{"Solid", "Outlined"}, &settings.ESP.Box.Mode, "Solid"),
					),

					Group("Health Bar",
						CreateToggle("Enabled", &settings.ESP.HealthBar.Enabled),
						//CreateList("Mode", []string{"Solid", "Bold", "Thin"}, &settings.ESP.HealthBar, "Solid"),
						CreateColorPickerButton("Top Color", &settings.ESP.HealthBar.TopColor, window),
						CreateColorPickerButton("Bottom Color", &settings.ESP.HealthBar.BottomColor, window),
					),
				),
			),
		)),
	),
	)

	window.ShowAndRun()
}
