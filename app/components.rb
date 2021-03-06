Sprite = Stomp.component("Sprite", :path)
LayerIndex = Stomp.component("LayerIndex", :value)
Size = Stomp.component("Size", :x, :y)

MenuItem = Stomp.component("MenuItem", :nonhover, :hover, :action, :hovered)

ExitAction = Stomp.component("ExitAction")

Position = Stomp.component("Position", :x, :y)
PreviousPosition = Stomp.component("PreviousPosition", :x, :y)
Velocity = Stomp.component("Velocity", :x, :y)
Acceleration = Stomp.component("Acceleration", :x, :y)
ScalarAcceleration = Stomp.component("ScalarAcceleration", :value)
MaxVelocity = Stomp.component("MaxVelocity", :value)

SetAcceleration = Stomp.component("SetAcceleration", :component, :x, :y)
AddAcceleration = Stomp.component("AddAcceleration", :component, :x, :y)
SetVelocity = Stomp.component("SetVelocity", :component, :x, :y)
LoseVelocity = Stomp.component("LoseVelocity", :component, :x, :y)
AddVelocity = Stomp.component("AddVelocity", :component, :x, :y)

LoseVelocityFactor = Stomp.component("LoseVelocityFactor", :value)

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
ForceParts::MAGNET = 3

Bond = Stomp.component("Bond", :id, :x, :y)
BondThread = Stomp.component("BondThread", :id1, :id2, :length, :power)
Fixed = Stomp.component("Fixed")

MouseArrow = Stomp.component("MouseArrow")

Scene = Stomp.component("Scene", :path)
CurrentScene = Stomp.component("CurrentScene", :value)

SwitchWorld = Stomp.component("SwitchWorld", :value)
SwitchWorldBack = Stomp.component("SwitchWorldBack")

Keybinding = Stomp.component("Keybinding", :key, :action)
KeybindingUp = Stomp.component("KeybindingUp", :key, :action)

DragByMouse = Stomp.component("DragByMouse")
DraggedByMouse = Stomp.component("DraggedByMouse")

CollisionShape = Stomp.component("CollisionShape", :layer)
CircleShape = Stomp.component("CircleShape", :x, :y, :r)
AabbShape = Stomp.component("AabbShape", :min_x, :min_y, :max_x, :max_y)
BroadAabbShape = Stomp.component("BroadAabbShape", :min_x, :min_y, :max_x, :max_y)
RigidShape = Stomp.component("RigidShape", :vertices)
InfiniteMassVsFixedBounce = Stomp.component("InfiniteMassVsFixedBounce", :value)
OnCollision = Stomp.component("OnCollision", :inflict_list, :take_list)

Restitution = Stomp.component("Restitution", :value)
StaticFriction = Stomp.component("StaticFriction", :value)
DynamicFriction = Stomp.component("DynamicFriction", :value)

PlanetSurface = Stomp.component("PlanetSurface")

AppendEntity = Stomp.component("AppendEntity", :type, :component_list)
Drop = Stomp.component("Drop", :component)
CreateEntity = Stomp.component("CreateEntity", :entity_list)

SetComponent = Stomp.component("SetComponent", :target, :component, :value)
AddToComponent = Stomp.component("AddToComponent", :target, :component, :value)
RemoveComponent = Stomp.component("RemoveComponent", :target, :component)

Health = Stomp.component("Health", :value)
DamageResistance = Stomp.component("DamageResistance", :value)
InflictedDamage = Stomp.component("InflictedDamage", :value)
OnDeath = Stomp.component("OnDeath", :inflict_list)
Decay = Stomp.component("Decay", :time)

Animation = Stomp.component("Animation", :length, :frames, :time)

TimedAction = Stomp.component("TimedAction", :timeout, :action, :time)

Magnet = Stomp.component("Magnet", :power)

Condition = Stomp.component("Condition", :predicate, :expectation, :action)
MultiCondition = Stomp.component("MultiCondition", :conditions, :action)

TextSprite = Stomp.component("TextSprite", :component)
# TextFormat: size: [w, h]; align: on_of[left, right]; margin: int
TextFormat = Stomp.component("TextFormat", :size, :align, :margin)
TextRenderingRules = Stomp.component("TextRenderingRules", :rules)
