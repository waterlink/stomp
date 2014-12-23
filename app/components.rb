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

Orient = Stomp.component("Orient", :value)
AngularVelocity = Stomp.component("AngularVelocity", :value)

Mass = Stomp.component("Mass", :value, :inverted)
Force = Stomp.component("Force", :x, :y)

Moment = Stomp.component("Moment", :value, :inverted)
Torque = Stomp.component("Torque", :value)

ForceParts = Stomp.component("ForceParts", :parts)
ForceParts::DRAG = 0
ForceParts::GRAVITY = 1
ForceParts::BOND = 2

Bond = Stomp.component("Bond", :id, :x, :y)
BondThread = Stomp.component("BondThread", :id1, :id2, :length, :power)
Fixed = Stomp.component("Fixed")

MouseArrow = Stomp.component("MouseArrow")

Scene = Stomp.component("Scene", :path)
CurrentScene = Stomp.component("CurrentScene", :value)

SwitchWorld = Stomp.component("SwitchWorld", :value)
SwitchWorldBack = Stomp.component("SwitchWorldBack")

Keybinding = Stomp.component("Keybinding", :key, :action)

DragByMouse = Stomp.component("DragByMouse")
DraggedByMouse = Stomp.component("DraggedByMouse")

CollisionShape = Stomp.component("CollisionShape")
CircleShape = Stomp.component("CircleShape", :x, :y, :r)
AabbShape = Stomp.component("AabbShape", :min_x, :min_y, :max_x, :max_y)
RigidShape = Stomp.component("RigidShape", :vertices)

Restitution = Stomp.component("Restitution", :value)
StaticFriction = Stomp.component("StaticFriction", :value)
DynamicFriction = Stomp.component("DynamicFriction", :value)

PlanetSurface = Stomp.component("PlanetSurface")
