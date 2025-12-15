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
	window := app.NewWindow("Base")
	window.Resize(fyne.NewSize(600, 400))

	window.SetContent(container.NewVScroll(

		container.NewAppTabs(
			container.NewTabItem("Aimbot", container.NewVBox(
				CreateToggle("Enabled", &settings.Aimbot.Enabled),
				CreateToggle("Hitscan", &settings.Aimbot.Hitscan.Enabled),
				CreateToggle("Autoshoot", &settings.Aimbot.Hitscan.Autoshoot),
				CreateKeySelection("Key", &settings.Aimbot.Hitscan.Key),
				CreateSlider("FOV", &settings.Aimbot.Hitscan.Fov, 0, 180),

				CreateToggle("Projectile", &settings.Aimbot.Proj.Enabled),
				CreateToggle("Autoshoot", &settings.Aimbot.Proj.Autoshoot),
				CreateToggle("FOV Indicator", &settings.Aimbot.FovIndicator),
				CreateKeySelection("Key", &settings.Aimbot.Proj.Key),
				CreateSlider("FOV", &settings.Aimbot.Proj.Fov, 0, 180),
				CreateSlider("Max Simulation Time", &settings.Aimbot.Proj.MaxSimTime, 0, 5),
			)),

			container.NewTabItem("Visuals", container.NewVBox(
				CreateCenterLabel("Glow"),
				CreateToggleFlag("Enabled", &settings.Glow.Flags, 0),

				CreateCenterLabel("Entity Filter"),

				CreateToggleFlag("Players", &settings.Glow.Flags, 1),
				CreateToggleFlag("Weapons", &settings.Glow.Flags, 2),
				CreateToggleFlag("Sentries", &settings.Glow.Flags, 3),
				CreateToggleFlag("Dispensers", &settings.Glow.Flags, 4),
				CreateToggleFlag("Teleporters", &settings.Glow.Flags, 5),
				CreateToggleFlag("ChristmasBall", &settings.Glow.Flags, 6),
				CreateToggleFlag("MedKit / Ammo", &settings.Glow.Flags, 7),
				CreateToggleFlag("ViewModel", &settings.Glow.Flags, 8),

				CreateSliderStepped("Blurriness", &settings.Glow.Blurriness, 0, 30, 1.0),
				CreateSliderStepped("Stencil", &settings.Glow.Stencil, 0, 30, 1.0),
			)),
		),
	))

	window.ShowAndRun()
}
