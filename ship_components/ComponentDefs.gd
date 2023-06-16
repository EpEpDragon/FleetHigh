extends Node

enum Type {HULL, HULL_LARGE, THRUSTER, THRUSTER_LARGE}

const Hull := preload("res://ship_components/hull/ShipComponenet.tscn")
const HullLarge := preload("res://ship_components/hull/ShipComponentLarge.tscn")
const Thruster := preload("res://ship_components/engine/ShipEngine.tscn")
const ThrusterLarge := preload("res://ship_components/engine/ShipEngineLarge.tscn")
