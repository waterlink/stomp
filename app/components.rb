Sprite = Stomp.component("Sprite", :path)
LayerIndex = Stomp.component("LayerIndex", :value)
Size = Stomp.component("Size", :x, :y)

Menu = Stomp.component("Menu")
MenuItem = Stomp.component("MenuItem", :nonhover, :hover, :action, :hovered)

ExitAction = Stomp.component("ExitAction")

Position = Stomp.component("Position", :x, :y)

MouseArrow = Stomp.component("MouseArrow")

Scene = Stomp.component("Scene", :path)
CurrentScene = Stomp.component("CurrentScene", :value)

Pause = Stomp.component("Pause")
PauseOnly = Stomp.component("PauseOnly")
