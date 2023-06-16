extends Node
class_name FuelComponent

@export var max_fuel : float = 33510 # L
var current_fuel : float = max_fuel:
	set(value):
		if current_fuel == 0 and clamp(value,0, max_fuel):
			owner.ship.wet_fuel_tanks += 1
		current_fuel = clamp(value,0, max_fuel)
		if current_fuel == 0:
			owner.ship.wet_fuel_tanks -= 1

func _ready():
	owner.fuel_component = self

func _exit_tree():
	if not owner.preview:
		owner.ship.max_fuel -= max_fuel
		owner.ship.wet_fuel_tanks -= 1
		owner.remove_mass(max_fuel * 422.8/1000_000)
	
func add_fuel_tank():
	owner.ship.max_fuel += max_fuel
	owner.ship.current_fuel = owner.ship.max_fuel
	owner.ship.wet_fuel_tanks += 1
	owner.add_mass(max_fuel * 422.8/1000_000) # Methane
	owner.ship.use_fuel.connect(use_fuel)
	owner.ship.refuel.connect(refuel)

func refuel():
	current_fuel = max_fuel

func use_fuel(amount):
	if current_fuel - amount < 0:
		pass
	current_fuel -= amount
	owner.ship.current_fuel -= amount

