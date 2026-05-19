class_name RunWorldPresentationController
extends RefCounted

const ContainerLifetimeViewScript := preload("res://scripts/ui/container_lifetime_view.gd")
const OutpostRequirementBubbleViewScript := preload("res://scripts/ui/outpost_requirement_bubble_view.gd")

var container_lifetime_view = ContainerLifetimeViewScript.new()
var outpost_requirement_bubble_view = OutpostRequirementBubbleViewScript.new()
var readable_overlay_host
var sync_outpost_visual_anchor: Callable = Callable()

func setup(p_unit: float, p_readable_overlay_host, p_sync_outpost_visual_anchor: Callable = Callable()) -> void:
	container_lifetime_view.setup(p_unit)
	readable_overlay_host = p_readable_overlay_host
	sync_outpost_visual_anchor = p_sync_outpost_visual_anchor

func update(container_root: Node, outpost_root: Node, player_root: Node, get_inventory_count: Callable) -> void:
	refresh_container_lifetime_visuals(container_root)
	refresh_material_lifetime_visuals(outpost_root)
	refresh_outpost_requirement_bubbles(outpost_root, get_inventory_count)
	refresh_readable_overlay_layout([container_root, outpost_root, player_root])

func refresh_container_lifetime_visuals(container_root: Node) -> void:
	if container_root == null:
		return
	for container in container_root.get_children():
		if not is_instance_valid(container) or not (container is Node2D):
			continue
		if container.get("interact_type") != "container":
			continue
		refresh_container_lifetime_visual(container)

func refresh_container_lifetime_visual(container: Node) -> void:
	container_lifetime_view.refresh_container(container)

func refresh_material_lifetime_visuals(outpost_root: Node) -> void:
	if outpost_root == null:
		return
	for material in outpost_root.get_children():
		if not is_instance_valid(material) or not (material is Node2D):
			continue
		if material.get("interact_type") != "material":
			continue
		refresh_material_lifetime_visual(material)

func refresh_material_lifetime_visual(material: Node) -> void:
	container_lifetime_view.refresh_material(material)

func refresh_outpost_requirement_bubbles(outpost_root: Node, get_inventory_count: Callable) -> void:
	if outpost_root == null:
		return
	for outpost in outpost_root.get_children():
		if not is_instance_valid(outpost) or outpost.get("interact_type") != "outpost":
			continue
		if sync_outpost_visual_anchor.is_valid():
			sync_outpost_visual_anchor.call(outpost)
		refresh_outpost_requirement_bubble(outpost, get_inventory_count)

func refresh_outpost_requirement_bubble(outpost: Node, get_inventory_count: Callable) -> void:
	outpost_requirement_bubble_view.refresh(outpost, get_inventory_count)

func refresh_readable_overlay_layout(roots: Array) -> void:
	if readable_overlay_host == null:
		return
	var scale_value := 1.0
	for root in roots:
		if root != null:
			readable_overlay_host.apply_readable_overlay_scale(root, scale_value)
