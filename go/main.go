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

	window.SetContent(container.NewVScroll(container.NewVBox(
		CreateToggle("Enabled", &settings.Aimbot.Enabled),
		CreateToggle("Hitscan", &settings.Aimbot.Hitscan.Enabled),
		CreateSlider("FOV", &settings.Aimbot.Hitscan.Fov, 0, 180),
		CreateKeySelection("Key", &settings.Aimbot.Hitscan.Key),

		CreateToggle("Projectile", &settings.Aimbot.Proj.Enabled),
		CreateSlider("FOV", &settings.Aimbot.Proj.Fov, 0, 180),
		CreateKeySelection("Key", &settings.Aimbot.Proj.Key),
	)))

	window.ShowAndRun()
}
