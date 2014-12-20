Sprite = Stomp.component("Sprite", :path)
LayerIndex = Stomp.component("LayerIndex", :value)
Size = Stomp.component("Size", :x, :y)

Menu = Stomp.component("Menu")
MenuItem = Stomp.component("MenuItem", :nonhover, :hover, :action, :hovered)

ExitAction = Stomp.component("ExitAction")

Position = Stomp.component("Position", :x, :y)
PreviousPosition = Stomp.component("PreviousPosition", :x, :y)
Velocity = Stomp.component("Velocity", :x, :y)
Acceleration = Stomp.component("Acceleration", :x, :y)

Mass = Stomp.component("Mass", :value)
Force = Stomp.component("Force", :x, :y)

MouseArrow = Stomp.component("MouseArrow")

Scene = Stomp.component("Scene", :path)
CurrentScene = Stomp.component("CurrentScene", :value)

DragByMouse = Stomp.component("DragByMouse")
DraggedByMouse = Stomp.component("DraggedByMouse")
